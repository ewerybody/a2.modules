import os
from copy import deepcopy

import a2ctrl
import a2path
import a2element.hotkey
from a2element import DrawCtrl, EditCtrl
from a2widget import a2hotkey, a2item_editor, key_value_table
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
    'scopeChange': True,
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
        self.editor.set_list_width(self.main.style.scale(170))
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
        # Gather ONLY hotkeys from editor data, no need to store anything else.
        # The sets stuff is just for display so far.
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


class UniFormatLister(a2item_editor.A2ItemEditor):
    def __init__(self, parent):
        self.draw_ctrl = parent
        super().__init__(parent)

        self.desc = QtWidgets.QLabel(wordWrap=True, openExternalLinks=True)
        self.enlist_widget('desc', self.desc, self.desc.setText, '')
        self.add_row(self.desc)

        hotkey_cfg_copy = deepcopy(_DEFAULT_HOTKEY)
        self.hotkey = a2element.hotkey.Draw(self, hotkey_cfg_copy)
        self.add_data_widget(
            'hotkey', self.hotkey, self.hotkey.set_config, self.hotkey.changed, hotkey_cfg_copy
        )

        self.table_lable = QtWidgets.QLabel()
        self.table_lable.setWordWrap(True)
        self.add_row(self.table_lable)

        self.key_value_table = key_value_table.KeyValueTable(self)
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

    def _set_hotkey_label(self, name):
        self.hotkey.label.setText(f'Format with "<b>{name}</b>" directly')
        this_data = self.data.get(name, {})
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
    if user_cfg.get(WIP_CHECK, False):
        db_dict['variables']['uniformat_show_wip'] = True

    for name, data in user_cfg.get('sets', {}).items():
        hotkey = data.get(a2hotkey.NAME)
        if hotkey is None:
            continue

        hk_cfg = deepcopy(_DEFAULT_HOTKEY)
        hk_cfg[a2element.hotkey.Vars.function_code] = f'uniformat_replace("{name}")'
        a2element.hotkey.get_settings(module_key, hk_cfg, db_dict, hotkey)
