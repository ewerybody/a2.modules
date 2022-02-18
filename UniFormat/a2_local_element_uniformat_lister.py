import os
from copy import deepcopy

import a2ctrl
import a2path
import a2element.hotkey
from a2element import DrawCtrl, EditCtrl
from a2widget import a2hotkey
from a2widget.a2item_editor import A2ItemEditor
from a2widget.key_value_table import KeyValueTable
from a2qt import QtWidgets

THIS_DIR = os.path.abspath(os.path.dirname(__file__))
SETS = os.path.join(THIS_DIR, 'sets')
WIP_CHECK = 'wip_check'
_DEFAULT_HOTKEY = {
    'enabled': False,
    'key': [''],
    'keyChange': True,
    'multiple': True,
    'scope': [],
    'scopeChange': False,
    'scopeMode': 0,
}
MSG_ALT = (
    'Values separated by space are alternatives (currently ignored!) '
    'Only the <b>first</b> is used!'
)


class Draw(DrawCtrl):
    def __init__(self, *args):
        super(Draw, self).__init__(*args)
        self.main_layout = QtWidgets.QVBoxLayout(self)
        self.main_layout.setContentsMargins(0, 0, 0, 0)

        self.editor = UniFormatLister(self)
        self.editor.data_changed.connect(self.delayed_check)
        self.main_layout.addWidget(self.editor)
        show_wip = self.user_cfg.get(WIP_CHECK, False)
        self.load_sets(show_wip)

        self.wip_check = QtWidgets.QCheckBox('Show WIP sets')
        self.wip_check.setToolTip(
            'Enable sets flagged "Work in Progress" to show in list and main menu.'
        )
        self.wip_check.setChecked(show_wip)
        self.wip_check.clicked.connect(self.delayed_check)
        self.wip_check.clicked.connect(self.load_sets)
        self.main_layout.addWidget(self.wip_check)

        self.is_expandable_widget = True

    def load_sets(self, show_wip=None):
        if show_wip is None:
            show_wip = self.user_cfg.get(WIP_CHECK, False)

        data = {}
        user_sets = self.user_cfg.get('sets', {})
        for item in a2path.iter_types(SETS, ['.txt']):
            this_data = _get_sets_data(item.path)
            if not this_data:
                continue
            if not show_wip and item.base.startswith('_ ') or 'wip' in this_data:
                continue
            this_hk = user_sets.get(item.base, {}).get(a2hotkey.NAME)
            if this_hk is not None:
                this_data[a2hotkey.NAME] = this_hk
            data[item.base] = this_data
        self.editor.set_data(data)

    def check(self):
        user_sets = self.user_cfg.get('sets', {})
        for name, set_data in self.editor.data.items():
            if a2hotkey.NAME not in set_data:
                if a2hotkey.NAME in user_sets.get(name, {}):
                    del user_sets[name][a2hotkey.NAME]
                continue
            user_sets.setdefault(name, {})[a2hotkey.NAME] = set_data[a2hotkey.NAME]
        self.user_cfg['sets'] = user_sets
        if self.wip_check.isChecked():
            self.user_cfg[WIP_CHECK] = True
        elif WIP_CHECK in self.user_cfg:
            del self.user_cfg[WIP_CHECK]
        self.set_user_value(self.user_cfg)
        self.change()


class UniFormatLister(A2ItemEditor):
    def __init__(self, parent):
        self.draw_ctrl = parent
        super().__init__(parent)

        self.desc = QtWidgets.QLabel(wordWrap=True, openExternalLinks=True)
        self.enlist_widget('desc', self.desc, self.desc.setText, '')
        self.add_row(self.desc)

        self.hotkey = a2element.hotkey.Draw(self, deepcopy(_DEFAULT_HOTKEY))
        self.hotkey.changed.connect(self._changed)

        self.add_row(self.hotkey)

        self.table_lable = QtWidgets.QLabel()
        self.table_lable.setWordWrap(True)
        self.add_row(self.table_lable)

        self.key_value_table = KeyValueTable(self)
        self.key_value_table.setEditTriggers(QtWidgets.QTableWidget.NoEditTriggers)
        self.selected_name_changed.connect(self._set_hotkey_label)
        self.key_value_table.changed.connect(self._update_data)
        self.enlist_widget('letters', self.key_value_table, self.key_value_table.set_data, {})
        self.add_row(self.key_value_table)

    def _update_data(self):
        if self.selected_name:
            have_data = self.data[self.selected_name]['data']
            table_data = self.key_value_table.get_data()
            if have_data != table_data:
                self.data[self.selected_name]['data'] = table_data
                self.data_changed.emit()

    def _changed(self):
        self.data[self.selected_name][a2hotkey.NAME] = self.hotkey.get_user_dict()
        self.data_changed.emit()

    def _set_hotkey_label(self, name):
        self.hotkey.label.setText(f'Format with "<b>{name}</b>" directly')

        this_data = self.data.get(name, {})
        this_hotkey = deepcopy(_DEFAULT_HOTKEY)
        this_hotkey.update(this_data.get(a2hotkey.NAME, {}))
        self.hotkey.set_config(this_hotkey)

        letters = this_data.get('letters', {})
        label = '<b>%i</b> keys. ' % len(letters)
        if any(' ' in v for v in letters.values()):
            label += MSG_ALT
        self.table_lable.setText(label)


class Edit(EditCtrl):
    """
    The background widget that sets up how the user can edit the element,
    visible when editing the module.
    """

    def __init__(self, cfg, main, parent_cfg):
        super(Edit, self).__init__(cfg, main, parent_cfg)

    @staticmethod
    def element_name():
        """The elements display name shown in UI"""
        return 'Uniformat_Lister'

    @staticmethod
    def element_icon():
        return a2ctrl.Icons.check


def _get_sets_data(path):
    data = {}  # type: dict[str, str | bool | dict]
    letters = {}  # type: dict[str, str]
    passed_comments = False
    with open(path, encoding='utf8') as file_obj:
        for line in file_obj:
            if not passed_comments and line.startswith('#'):
                line = line.strip('# ')
                if not line:
                    continue
                pieces = line.split('=', 1)
                if len(pieces) == 1 or ' ' in pieces[0]:
                    continue
                data[pieces[0].strip()] = pieces[1].strip()
                continue
            passed_comments = True
            pieces = line.rstrip().split(' ', 1)
            if len(pieces) <= 1:
                continue
            letters[pieces[0]] = pieces[1]
    data['letters'] = letters
    return data


def get_settings(module_key, cfg, db_dict, user_cfg):
    """
    Called by the module on "change" to get an elements data thats
    eventually written into the runtime includes.

    Passed into is all you might need:
    :param str module_key: "module_source_name|module_name" combo used to identify module in db
    :param dict cfg: Standard element configuration dictionary.
    :param dict db_dict: Dictionary that's used to write the include data with "hotkeys", "variables" and "includes" keys
    :param dict user_cfg: This elements user edits saved in the db

    To make changes to the:
    * "variables" - a simple key, value dictionary in db_dict

    Get the current value via get_cfg_value() given the default cfg and user_cfg.
    If value name is found it takes the value from there, otherwise from cfg or given default.

        value = a2ctrl.get_cfg_value(cfg, user_cfg, typ=bool, default=False)

    write the key and value to the "variables" dict:

        db_dict['variables'][cfg['name']] = value

    * "hotkeys" - a dictionary with scope identifiers

    * "includes" - a simple list with ahk script paths
    """
    if user_cfg.get(WIP_CHECK, False):
        db_dict['variables']['uniformat_show_wip'] = True

    for data in user_cfg.get('sets', {}).values():
        hotkey = data.get(a2hotkey.NAME)
        if hotkey is not None:
            if not hotkey.get('enabled', False):
                continue
            key = hotkey.get('key')
            if not key or not key[0]:
                continue

            func = f'uniformat_replace("{data["name"]}")'
            scope = hotkey.get(a2hotkey.Vars.scope, [])
            scope_mode = hotkey.get(a2hotkey.Vars.scope_mode, 0)

            db_dict.setdefault('hotkeys', {})
            db_dict['hotkeys'].setdefault(scope_mode, [])
            # save a global if global scope set or all-but AND scope is empty
            if scope_mode == 0 or scope_mode == 2 and scope == '':
                db_dict['hotkeys'][0].append([key, func])
            else:
                db_dict['hotkeys'][scope_mode].append([scope, key, func])
