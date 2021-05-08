import os
import sys
import hashlib
from copy import deepcopy

from a2qt import QtWidgets, QtCore

import a2util
import a2ctrl
import a2core
from a2element import DrawCtrl, EditCtrl
from a2widget import a2item_editor, a2text_field, a2input_dialog, a2more_button

this_dir = os.path.dirname(__file__)
if this_dir not in sys.path:
    sys.path.append(this_dir)
import hotstrings_io
from hotstrings_io import Options


ADD_SCOPE_TXT = 'Add Group'
ADD_MSG = 'Pick a name for the new group:'


class Args:
    enabled = 'enabled'
    groups = 'groups'
    hotstrings = 'hotstrings'
    last_group = 'last_group'
    scopes = 'scopes'
    scope_type = 'scope_type'


GLOBAL_SCOPE_TXT = 'global'
HOTSTRINGS_FILENAME = Args.hotstrings + '.ahk'
HS_CHECKBOXES = [
    (Options.instant.name, 'Triggered Immediately (otherwise by Space, Enter ...)'),
    (Options.ignore.name, 'Ignore Characters Causing Replacement'),
    (Options.inside.name, 'Replace Inside Words'),
    (Options.append.name, "Don't Replace Abbreviation, Just append"),
]

MODES = [
    'a2 default - escape "!+^#"',
    'Execute as Autohotkey code',
    'Let !+^# press Ctrl, Shift, Alt, Win',
    'Raw - Control-Characters as Plain Text',
    'Text - new. Similar to raw mode.',
]
CASE_ITEMS = ['Forward to text', 'Sensitive', 'Keep original']
ICONS = {
    None: a2ctrl.Icons.scope_global,
    hotstrings_io.KEY_INCL: a2ctrl.Icons.scope,
    hotstrings_io.KEY_EXCL: a2ctrl.Icons.scope_exclude,
}


class HotStringsEditor(a2item_editor.A2ItemEditor):
    """
    List widget to show & edit a single hotstrings group at a time.
    """

    def __init__(self, user_cfg, parent):
        self.data = user_cfg
        super(HotStringsEditor, self).__init__(parent)

        self.ui.text = a2text_field.A2TextField(self)
        self.add_data_widget(
            'text',
            self.ui.text,
            self.ui.text.setText,
            self.ui.text.editing_finished,
            default_value='',
        )

        for name, label in HS_CHECKBOXES:
            checkbox = QtWidgets.QCheckBox(self)
            checkbox.setText(label)
            self.add_data_widget(name, checkbox, checkbox.setChecked, default_value=False)

        self.ui.mode = QtWidgets.QComboBox(self)
        self.ui.mode.addItems(MODES)
        self.add_data_label_widget(
            'mode', self.ui.mode, self.ui.mode.setCurrentIndex, default_value=0, label='Mode'
        )

        self.ui.case = QtWidgets.QComboBox(self)
        self.ui.case.addItems(CASE_ITEMS)
        self.add_data_label_widget(
            'case', self.ui.case, self.ui.case.setCurrentIndex, default_value=0
        )

        self.ui.sendmode = QtWidgets.QComboBox(self)
        self.ui.sendmode.addItems(['Default', 'SendInput', 'SendPlay', 'SendEvent'])
        self.add_data_label_widget(
            'send',
            self.ui.sendmode,
            self.ui.sendmode.setCurrentIndex,
            default_value=0,
            label='Send Method',
        )

        self.enable_search_field(False)

    def insert_scope_ui(self, widget):
        self.ui.list_layout.insertWidget(0, widget)


class Draw(DrawCtrl):
    """
        The complete Hotstrings editor displaying all our groups,
        assembling the resulting dictionary passing it to the AHK code generator.

        A Hotstrings group can have any name (except for internal '', 'scope_incl', 'scope_excl')
        it can be scoped however you want making it work globally or on certain windows only,
        it can also be enabled/disabled, renamed.
        When doing imports new groups are created. If there are multiple scopes

        user_cfg be like:
    {
        'last_group': '',
        'last_selection': '',
        'groups': {
            'global': {
                'enabled': True,
                'hotstrings': {
                    'shortcut1': {
                        'text': some_string,
                        'ignore' True,
                        'mode': ...
                    '...':

            'some name': {
                'scopes': [],
                'scope_type': 'scope_incl'
                ...

    """

    def __init__(self, *args):
        super(Draw, self).__init__(*args)
        self._hs_code_b4 = None

        if _check_legacy_data(self.user_cfg):
            self.delayed_check()

        self.current_name = self.user_cfg.get(Args.last_group, GLOBAL_SCOPE_TXT)
        self.current_group = self.groups.get(self.current_name, {})

        self._setup_ui()
        self.hotstrings_file = os.path.join(self.mod.data_path, HOTSTRINGS_FILENAME)
        self._check_hs_include_file()

        self.is_expandable_widget = True
        QtCore.QTimer(self).singleShot(50, self.fill_group_combo)

    @property
    def groups(self):
        return self.user_cfg.get(Args.groups, {})

    def _setup_ui(self):
        self.main_layout = QtWidgets.QVBoxLayout(self)
        self.main_layout.setContentsMargins(0, 0, 0, 0)
        self.editor = HotStringsEditor(self.current_group.get(Args.hotstrings, {}), self)
        self.editor.list_menu_called.connect(self.build_list_context_menu)
        self.editor.data_changed.connect(self.delayed_check)
        self.main_layout.addWidget(self.editor)

        widget = QtWidgets.QWidget(self)
        layout = QtWidgets.QHBoxLayout(widget)
        layout.setContentsMargins(0, 0, 0, 0)
        self.group_combo = QtWidgets.QComboBox(self)
        self.group_combo.currentTextChanged.connect(self.on_group_change)
        layout.addWidget(self.group_combo)
        self.more_button = a2more_button.A2MoreButton(self)
        self.more_button.menu_called.connect(self.build_group_edit_menu)
        layout.addWidget(self.more_button)
        self.editor.insert_scope_ui(widget)

    def fill_group_combo(self):
        self.group_combo.blockSignals(True)
        self.group_combo.clear()

        if self.groups:
            for name, group in self.groups.items():
                self.group_combo.addItem(ICONS[group.get(Args.scope_type)], name)
        else:
            self.current_name = GLOBAL_SCOPE_TXT
            self.current_scope = self.user_cfg[Args.groups] = {GLOBAL_SCOPE_TXT: {}}
            self.group_combo.addItem(ICONS[None], GLOBAL_SCOPE_TXT)

        self.group_combo.addItem(a2ctrl.Icons.list_add, ADD_SCOPE_TXT)
        self.group_combo.setCurrentText(self.current_name)
        self.group_combo.blockSignals(False)

    def select_group(self, group_name):
        current_groups = list(self.user_cfg.get(Args.groups, {}))
        if group_name not in current_groups:
            group_name = self.user_cfg.get(Args.last_group, current_groups[0])
        self.group_combo.setCurrentText(group_name)

    # def add_scope_dialog(self):
    #     from a2widget.a2hotkey import scope_dialog

    #     dialog = scope_dialog.get_changable_no_global(self)
    #     dialog.okayed.connect(self.scope_add_done)
    #     dialog.rejected.connect(self._unselect_add_option)
    #     dialog.show()

    # def on_scope_change(self, index):
    #     if index == self.scope_combo.count() - 1:
    #         self.add_scope_dialog()
    #         return

    #     self._last_scope_index = index

    #     self.scope_key, self.scope_string = self._scope_combo_items[index]
    #     if self.scope_key == '':
    #         self.current_scope = self.user_cfg['']
    #     else:
    #         self.current_scope = self.user_cfg[self.scope_key][self.scope_string]
    #     self.editor.set_data(self.current_scope)

    # def _unselect_add_option(self):
    #     self.scope_combo.blockSignals(True)
    #     self.scope_combo.setCurrentIndex(self._last_scope_index)
    #     self.scope_combo.blockSignals(False)

    # def scope_add_done(self, scope_cfg):
    #     from a2widget.a2hotkey.hotkey_common import Vars

    #     scope_string = '\n'.join(scope_cfg.get(Vars.scope, []))
    #     if scope_string:
    #         mode_id = scope_cfg.get(Vars.scope_mode, 1) - 1
    #         scope_key = [hotstrings_io.KEY_INCL, hotstrings_io.KEY_EXCL][mode_id]
    #         self.user_cfg.setdefault(scope_key, {})[scope_string] = {}
    #         self.fill_group_combo()
    #         self.select_scope(scope_key, scope_string)

    def edit_scope(self):
        from a2widget.a2hotkey import scope_dialog, Vars

        scope_dict = {}
        scope_dict[Vars.scope_mode] = {hotstrings_io.KEY_INCL: 1, hotstrings_io.KEY_EXCL: 2}[
            self.scope_key
        ]
        scope_dict[Vars.scope] = self.scope_string.split('\n')

        dialog = scope_dialog.get_changable_no_global(self, scope_dict)
        dialog.okayed.connect(self.scope_edit_done)
        dialog.show()

    def remove_group(self):
        if self.current_name not in self.user_cfg.get(Args.groups, {}):
            return

        if self.current_group.get(Args.hotstrings):
            dialog = a2input_dialog.A2ConfirmDialog(
                self.main,
                'Remove group "%s" ...' % self.current_name,
                'The group still contains Hotstings! These would be lost!\n'
                'You can also <b>move</b> the Hotstrings to other groups or '
                'make them scoped via context menu.\nOr do you want to continue deletion?',
            )
            dialog.exec_()
            if not dialog.result:
                return

        del self.user_cfg[Args.groups][self.current_name]
        self.fill_group_combo()
        # self.scope_combo.setCurrentIndex(0)
        # self.on_scope_change(0)
        self.check()

    # def scope_edit_done(self, scope_cfg):
    #     from a2widget.a2hotkey.hotkey_common import Vars

    #     scope_string = '\n'.join(scope_cfg.get(Vars.scope, []))
    #     if scope_string:
    #         mode_id = scope_cfg.get(Vars.scope_mode, 1) - 1
    #         scope_key = [hotstrings_io.KEY_INCL, hotstrings_io.KEY_EXCL][mode_id]
    #         if scope_key == self.scope_key and scope_string == self.scope_string:
    #             return

    #         # remove the current setting ...
    #         del self.user_cfg[self.scope_key][self.scope_string]
    #         # and the mode key if changed and empty
    #         if scope_key != self.scope_key and not self.user_cfg[self.scope_key]:
    #             del self.user_cfg[self.scope_key]

    #         self.user_cfg.setdefault(scope_key, {})[scope_string] = self.current_scope
    #         self.fill_group_combo()
    #         self.select_scope(scope_key, scope_string)

    def check(self, *args):
        """Write the hotstrings AHK code and call `change()`."""
        self.current_group[Args.hotstrings] = deepcopy(self.editor.data)
        self.set_user_value(self.user_cfg)

        # create an old-style hotstrings dictionary to pass it to the
        # AHK-Hotstrings-code generator
        hs_dict = {}
        for group in self.user_cfg.get(Args.groups, {}).values():
            if not group.get(Args.enabled, True):
                continue

            if scope_type := group.get(Args.scope_type):
                target_dict = hs_dict.setdefault(scope_type, {})
                for scope_str in group.get(Args.scopes):
                    target_dict.setdefault(scope_str, {}).update(group.get(Args.hotstrings))
            else:
                hs_dict.setdefault('', {}).update(group.get(Args.hotstrings))

        hotstrings_code = hotstrings_io.dict_to_ahkcode(hs_dict)
        code_hash = hashlib.sha1(hotstrings_code.encode('utf8'))
        if code_hash == self._hs_code_b4:
            return

        self._hs_code_b4 = code_hash

        hotstrings_code = a2core.EDIT_DISCLAIMER % HOTSTRINGS_FILENAME + '\n' + hotstrings_code
        self._write(hotstrings_code)
        self.change()

    def _check_hs_include_file(self):
        """Make sure at least an empty file is there to be included."""
        os.makedirs(self.mod.data_path, exist_ok=True)
        if not os.path.isfile(self.hotstrings_file):
            self._write('')

    def _write(self, hotstrings_code):
        a2util.write_utf8(self.hotstrings_file, hotstrings_code)
        # To avoid a2-runtime auto-reload, set archive flag immediately
        a2util.set_archive(self.hotstrings_file, False)

    def build_group_edit_menu(self, menu):
        if self.current_group.get(Args.enabled, True):
            menu.addAction(a2ctrl.Icons.check, 'Disable Group', self.disable_group)
        else:
            menu.addAction(a2ctrl.Icons.check, 'Enable Group', self.enable_group)
        action = menu.addAction(a2ctrl.Icons.edit, 'Edit Scope', self.edit_scope)
        action.setEnabled(False)
        menu.addAction(a2ctrl.Icons.edit, 'Rename Group', self.rename_group)
        menu.addAction(a2ctrl.Icons.delete, 'Remove Group', self.remove_group)
        menu.addAction(a2ctrl.Icons.list_add, ADD_SCOPE_TXT, self.add_group)

    def build_list_context_menu(self, menu):
        menu.clear()
        submenu = menu.addMenu(a2ctrl.Icons.scope, 'Move to Group')
        for name, group in self.groups.items():
            if name == self.current_name:
                continue

            action = submenu.addAction(
                ICONS[group.get(Args.scope_type)], name, self._on_move_hotstring
            )

        if submenu.isEmpty():
            action = submenu.addAction('No other groups set up!')
            action.setEnabled(False)

        menu.addAction(a2ctrl.Icons.delete, 'Remove Hotstring', self.editor.delete_item)

    def _on_move_hotstring(self):
        target_name = self.sender().text()
        target_group = self.user_cfg[Args.groups].get(target_name, {}).get(Args.hotstrings, {})

        if self.editor.selected_name in target_group:
            dialog = a2input_dialog.A2ConfirmDialog(
                self.main,
                'Group already contains "%s"!' % self.editor.selected_name,
                'The target group "%s"\nalready contains a Hotstings like "<b>%s</b>"!\n'
                'It would be <b>overwritten</b>! Do you want to continue?'
                % (target_name, self.editor.selected_name),
            )
            dialog.exec_()
            if not dialog.result:
                return

        hotstring_data = self.current_group[Args.hotstrings][self.editor.selected_name]
        del self.current_group[Args.hotstrings][self.editor.selected_name]
        target_group[self.editor.selected_name] = hotstring_data
        self.editor.set_data(self.current_group.get(Args.hotstrings, {}))
        self.check()

    def disable_group(self):
        self.current_group[Args.enabled] = False
        self.check()

    def enable_group(self):
        if Args.enabled in self.current_group:
            del self.current_group[Args.enabled]
        self.check()

    def add_group(self):
        dialog = a2input_dialog.A2InputDialog(
            self, ADD_SCOPE_TXT, self._add_group_check, msg=ADD_MSG
        )
        dialog.okayed.connect(self._on_add_group)
        dialog.exec_()

    def _add_group_check(self, name):
        if not name.strip():
            return 'Group name cannot be empty!'
        if name in self.user_cfg.get(Args.groups, {}):
            return 'Group name already exists!'
        if name in list(hotstrings_io.IN_EXCLUDE) + [ADD_SCOPE_TXT]:
            return 'Reserved Name not allowed!'
        return True

    def _on_add_group(self, new_group_name):
        self.current_name = new_group_name
        self.user_cfg.setdefault(Args.groups, {})[new_group_name] = {}
        self.current_group = self.user_cfg[Args.groups][new_group_name]
        self.fill_group_combo()
        self.select_group(new_group_name)

    def on_group_change(self, name):
        if name == ADD_SCOPE_TXT:
            self.add_group()
            if self.group_combo.currentText() == ADD_SCOPE_TXT:
                self.select_group(self.user_cfg.get(Args.last_group))
            return

        self.current_name = name
        self.current_group = self.groups.get(name, {})
        self.editor.set_data(self.current_group.get(Args.hotstrings, {}))
        self.set_user_value(name, Args.last_group)
        self.user_cfg[Args.last_group] = name

    def rename_group(self):
        pass


class Edit(EditCtrl):
    def __init__(self, *args):
        super(Edit, self).__init__(*args)
        self.mainLayout.addWidget(
            QtWidgets.QLabel(
                'Nothing to setup on the HotStrings element. This one is all for the user.'
            )
        )

    @staticmethod
    def element_name():
        """The elements display name shown in UI"""
        return 'Hotstrings'

    @staticmethod
    def element_icon():
        return a2ctrl.Icons.hotkey


def _check_legacy_data(cfg):
    """Make sure we use groups instead of ''-means global/scope_type pattern."""
    changed = False
    # move implied global scope '' to actual "global" group
    if '' in cfg:
        _legacy_move_group(cfg, '', GLOBAL_SCOPE_TXT)
        changed = True
    # move each scoped sub group to new group
    for scope_type in hotstrings_io.IN_EXCLUDE:
        if scope_type in cfg:
            for scope_key in cfg[scope_type].keys():
                new_name = _legacy_move_group(cfg, scope_type, scope_key)
                cfg[Args.groups][new_name][Args.scopes] = [scope_key]
                cfg[Args.groups][new_name][Args.scope_type] = scope_type
            changed = True
    return changed


def _legacy_move_group(cfg, old_name, new_name):
    cfg.setdefault(Args.groups, {})
    new_name = a2util.get_next_free_number(new_name, cfg[Args.groups].keys())
    cfg[Args.groups][new_name] = {Args.hotstrings: {}}
    cfg[Args.groups][new_name][Args.hotstrings] = cfg[old_name]
    del cfg[old_name]
    return new_name


def get_settings(_module_key, _cfg, db_dict, _user_cfg):
    """
    So far this only adds the hotstrings.ahk to includes.
    """
    db_dict.setdefault('data_includes', []).append(HOTSTRINGS_FILENAME)
