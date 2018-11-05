# -*- coding: utf-8 -*-
import os
import sys
import a2util
import a2ctrl
import a2runtime
from PySide2 import QtWidgets, QtCore
from a2element import DrawCtrl, EditCtrl
from a2widget.a2item_editor import A2ItemEditor
from a2widget import A2TextField
from a2widget.a2more_button import A2MoreButton

this_dir = os.path.dirname(__file__)
if this_dir not in sys.path:
    sys.path.append(this_dir)
import hotstrings_io
from hotstrings_io import Options


ADD_SCOPE_TXT = 'add scope'
GLOBAL_SCOPE_TXT = 'global'
HOTSTRINGS_FILENAME = 'hotstrings.ahk'
HS_CHECKBOXES = [
    (Options.instant.name, 'Triggered Immediately (otherwise by Space, Enter ...)'),
    (Options.ignore.name, 'Ignore Characters Causing Replacement'),
    (Options.inside.name, 'Replace Inside Words'),
    (Options.append.name, 'Don\'t Replace Abbreviation, Just append')]

MODES = ['a2 default - escape "!+^#"',
         'Execute as Autohotkey code',
         'Let !+^# press Ctrl, Shift, Alt, Win',
         'Raw - Control-Characters as Plain Text',
         'Text - new. Similar to raw mode.']
CASE_ITEMS = ['Forward to text', 'Sensitive', 'Keep original']


class HotStringsEditor(A2ItemEditor):
    def __init__(self, user_cfg, parent):
        self.data = user_cfg
        super(HotStringsEditor, self).__init__(parent)

        self.ui.text = A2TextField(self)
        self.add_data_widget('text', self.ui.text, self.ui.text.setText, self.ui.text.editing_finished,
                             default_value='')

        for name, label in HS_CHECKBOXES:
            checkbox = QtWidgets.QCheckBox(self)
            checkbox.setText(label)
            self.add_data_widget(name, checkbox, checkbox.setChecked, default_value=False)

        self.ui.mode = QtWidgets.QComboBox(self)
        self.ui.mode.addItems(MODES)
        self.add_data_label_widget('mode', self.ui.mode, self.ui.mode.setCurrentIndex,
                                   default_value=0, label='Mode')

        self.ui.case = QtWidgets.QComboBox(self)
        self.ui.case.addItems(CASE_ITEMS)
        self.add_data_label_widget('case', self.ui.case, self.ui.case.setCurrentIndex,
                                   default_value=0)

        self.ui.sendmode = QtWidgets.QComboBox(self)
        self.ui.sendmode.addItems(['Default', 'SendInput', 'SendPlay', 'SendEvent'])
        self.add_data_label_widget('send', self.ui.sendmode, self.ui.sendmode.setCurrentIndex,
                                   default_value=0, label='Send Method')

        self.enable_search_field(False)

    def insert_scope_ui(self, widget):
        self.ui.list_layout.insertWidget(0, widget)


class Draw(DrawCtrl):
    """
    The frontend widget visible to the user with options
    to change the default behavior of the element.
    """
    def __init__(self, *args):
        # cfg.setdefault('name', 'hotstrings')
        super(Draw, self).__init__(*args)
        self._hs_code_b4 = None
        # getting global hotstrings on init
        self.current_scope = self.user_cfg.get('', {})
        self._setup_ui()
        self.is_expandable_widget = True
        self.hotstrings_file = os.path.join(self.mod.data_path, HOTSTRINGS_FILENAME)
        self._check_hs_include_file()

        self.scope_key = ''
        self.scope_string = ''

    def _setup_ui(self):
        self.main_layout = QtWidgets.QVBoxLayout(self)
        self.main_layout.setContentsMargins(0, 0, 0, 0)
        self.editor = HotStringsEditor(self.current_scope, self)
        self.editor.list_menu_called.connect(self.build_list_context_menu)
        self.editor.data_changed.connect(self.delayed_check)
        self.main_layout.addWidget(self.editor)

        widget = QtWidgets.QWidget(self)
        layout = QtWidgets.QHBoxLayout(widget)
        layout.setContentsMargins(0, 0, 0, 0)
        self.scope_combo = QtWidgets.QComboBox(self)
        self.scope_combo.currentIndexChanged.connect(self.on_scope_change)
        layout.addWidget(self.scope_combo)
        self.scope_more_button = A2MoreButton(self)
        self.scope_more_button.menu_called.connect(self.build_scope_edit_menu)
        layout.addWidget(self.scope_more_button)

        self.editor.insert_scope_ui(widget)
        self._last_scope_index = 0
        QtCore.QTimer(self).singleShot(50, self.fill_scope_combo)

    def fill_scope_combo(self):
        self._scope_combo_items = {0: ('', None)}

        self.scope_combo.blockSignals(True)
        self.scope_combo.clear()
        i = self.scope_combo.addItem(a2ctrl.Icons.inst().scope_global, GLOBAL_SCOPE_TXT)
        for scope_key, scope_data in self.user_cfg.items():
            if scope_key == '':
                continue
            if scope_key == hotstrings_io.KEY_INCL:
                icon = a2ctrl.Icons.inst().scope
            elif scope_key == hotstrings_io.KEY_EXCL:
                icon = a2ctrl.Icons.inst().scope_exclude
            else:
                continue

            for scope_string in scope_data.keys():
                index = self.scope_combo.count()
                self.scope_combo.addItem(icon, scope_string.replace('\n', ''))
                item_data = (scope_key, scope_string)
                self.scope_combo.setItemData(index, item_data)
                self._scope_combo_items[index] = item_data

        self.scope_combo.addItem(a2ctrl.Icons.inst().list_add, ADD_SCOPE_TXT)
        self.scope_combo.blockSignals(False)

    def select_scope(self, scope_key, scope_string):
        for index, (this_key, this_string) in self._scope_combo_items.items():
            if this_key == scope_key and this_string == scope_string:
                self.scope_combo.setCurrentIndex(index)
                break

    def add_scope_dialog(self):
        from a2widget.a2hotkey import scope_dialog
        dialog = scope_dialog.get_changable_no_global(self)
        dialog.okayed.connect(self.scope_add_done)
        dialog.rejected.connect(self._unselect_add_option)
        dialog.show()

    def on_scope_change(self, index):
        if index == self.scope_combo.count() - 1:
            self.add_scope_dialog()
            return

        self._last_scope_index = index

        self.scope_key, self.scope_string = self._scope_combo_items[index]
        if self.scope_key == '':
            self.current_scope = self.user_cfg['']
        else:
            self.current_scope = self.user_cfg[self.scope_key][self.scope_string]
        self.editor.set_data(self.current_scope)

    def _unselect_add_option(self):
        self.scope_combo.blockSignals(True)
        self.scope_combo.setCurrentIndex(self._last_scope_index)
        self.scope_combo.blockSignals(False)

    def scope_add_done(self, scope_cfg):
        from a2widget.a2hotkey.hotkey_common import Vars
        scope_string = '\n'.join(scope_cfg.get(Vars.scope, []))
        if scope_string:
            mode_id = scope_cfg.get(Vars.scope_mode, 1) - 1
            scope_key = [hotstrings_io.KEY_INCL, hotstrings_io.KEY_EXCL][mode_id]
            self.user_cfg.setdefault(scope_key, {})[scope_string] = {}
            self.fill_scope_combo()
            self.select_scope(scope_key, scope_string)

    def edit_scope(self):
        from a2widget.a2hotkey import scope_dialog, Vars
        scope_dict = {}
        scope_dict[Vars.scope_mode] = {
            hotstrings_io.KEY_INCL: 1, hotstrings_io.KEY_EXCL: 2}[self.scope_key]
        scope_dict[Vars.scope] = self.scope_string.split('\n')

        dialog = scope_dialog.get_changable_no_global(self, scope_dict)
        dialog.okayed.connect(self.scope_edit_done)
        dialog.show()

    def remove_scope(self):
        if not self.current_scope:
            del self.user_cfg[self.scope_key][self.scope_string]
            self.fill_scope_combo()
        else:
            # TODO: what happens here?!
            print('self.current_scope', self.current_scope)
            print('self.scope_key', self.scope_key)

    def scope_edit_done(self, scope_cfg):
        from a2widget.a2hotkey.hotkey_common import Vars
        scope_string = '\n'.join(scope_cfg.get(Vars.scope, []))
        if scope_string:
            mode_id = scope_cfg.get(Vars.scope_mode, 1) - 1
            scope_key = [hotstrings_io.KEY_INCL, hotstrings_io.KEY_EXCL][mode_id]
            if scope_key == self.scope_key and scope_string == self.scope_string:
                return

            # remove the current setting ...
            del self.user_cfg[self.scope_key][self.scope_string]
            # and the mode key if changed and empty
            if scope_key != self.scope_key and not len(self.user_cfg[self.scope_key]):
                del self.user_cfg[self.scope_key]

            self.user_cfg.setdefault(scope_key, {})[scope_string] = self.current_scope
            self.fill_scope_combo()
            self.select_scope(scope_key, scope_string)

    def check(self, *args):
        if self.scope_key == '':
            self.user_cfg[''] = self.editor.data
        else:
            self.user_cfg[self.scope_key][self.scope_string] = self.editor.data

        self.set_user_value(self.user_cfg)

        hotstrings_code = hotstrings_io.dict_to_ahkcode(self.user_cfg)
        if hotstrings_code == self._hs_code_b4:
            return
        self._hs_code_b4 = hotstrings_code

        hotstrings_code = a2runtime.EDIT_DISCLAIMER % 'hotstrings' + '\n' + hotstrings_code
        a2util.write_utf8(self.hotstrings_file, hotstrings_code)

        self.change()

    def _check_hs_include_file(self):
        # make sure at least an empty file is there to be included
        os.makedirs(self.mod.data_path, exist_ok=True)
        if not os.path.isfile(self.hotstrings_file):
            with open(self.hotstrings_file, 'w') as fobj:
                fobj.write('')

    def build_scope_edit_menu(self, menu):
        if self.scope_combo.currentIndex() != 0:
            menu.addAction(a2ctrl.Icons.inst().edit, 'Edit Scope', self.edit_scope)
            menu.addAction(a2ctrl.Icons.inst().delete,
                           'Remove Scope', self.remove_scope)
        menu.addAction(a2ctrl.Icons.inst().list_add,
                       'Add Scope', self.add_scope_dialog)

    def build_list_context_menu(self, menu):
        menu.clear()
        action = menu.addAction(a2ctrl.Icons.inst().scope, 'Move to Scope ...')
        action.setEnabled(False)
        action = menu.addAction(a2ctrl.Icons.inst().delete, 'Remove Hotstring')
        action.setEnabled(False)


class Edit(EditCtrl):
    def __init__(self, *args):
        super(Edit, self).__init__(*args)
        self.mainLayout.addWidget(QtWidgets.QLabel(
            'Nothing to setup on the HotStrings element. This one is all for the user.'))

    @staticmethod
    def element_name():
        """The elements display name shown in UI"""
        return 'Hotstrings'

    @staticmethod
    def element_icon():
        return a2ctrl.Icons.inst().hotkey


def get_settings(_module_key, _cfg, db_dict, _user_cfg):
    """
    So far this only adds the hotstrings.ahk to includes.
    """
    db_dict.setdefault('data_includes', []).append(HOTSTRINGS_FILENAME)
