# -*- coding: utf-8 -*-
import os
import sys
import a2util
import a2ctrl
import a2runtime
from PySide2 import QtWidgets
from a2element import DrawCtrl, EditCtrl
from a2widget.a2item_editor import A2ItemEditor
from a2widget import A2TextField

this_dir = os.path.dirname(__file__)
if this_dir not in sys.path:
    sys.path.append(this_dir)
import hotstrings_io
from hotstrings_io import Options


ADD_SCOPE_TXT = 'add scope'
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

    def _setup_ui(self):
        self.main_layout = QtWidgets.QVBoxLayout(self)
        self.main_layout.setContentsMargins(0, 0, 0, 0)
        self.editor = HotStringsEditor(self.current_scope, self)
        self.editor.data_changed.connect(self.delayed_check)
        self.main_layout.addWidget(self.editor)

        self.scope_combo = QtWidgets.QComboBox(self)
        self.fill_scope_combo()
        self.scope_combo.currentTextChanged.connect(self.on_scope_change)
        self.editor.insert_scope_ui(self.scope_combo)

    def fill_scope_combo(self):
        self.scope_combo.addItem(a2ctrl.Icons.inst().scope_global, 'global')
        # for scope_key, scope_data in self.user_cfg.items():
        #     if scope_key == '':
        #         continue
        #     if scope_key is hotstrings_io.KEY_INCL:
        #         icon = a2ctrl.Icons.inst().scope
        #     elif scope_key is hotstrings_io.KEY_EXCL:
        #         icon = a2ctrl.Icons.inst().scope_exclude
        #     else:
        #         print('scope_key', scope_key)
        #
        #     for scope_string in scope_data.items():
        #         self.scope_combo.addItem(icon, scope_string)
        self.scope_combo.addItem(a2ctrl.Icons.inst().list_add, ADD_SCOPE_TXT)

    def on_scope_change(self, text):
        if text == ADD_SCOPE_TXT:
            from a2widget.a2hotkey import scope_dialog
            dialog = scope_dialog.get_changable_no_global(self)
            dialog.okayed.connect(self.scope_add_done)
            dialog.show()

    def scope_add_done(self, scope_cfg):
        # {'scopeChange': True, 'scopeMode': 1, 'scope': ['Qt Designer ahk_class QWidget ahk_exe designer.exe']}
        from a2widget.a2hotkey.hotkey_common import Vars
        scope_string = '\n'.join(scope_cfg.get(Vars.scope, []))
        if scope_string:
            print('scope_string: %s' % scope_string)
            mode_id = scope_cfg.get(Vars.scope_mode, 1) - 1
            scope_key = [hotstrings_io.KEY_INCL, hotstrings_io.KEY_EXCL][mode_id]
            print('scope_mode: %s' % scope_key)
            self.user_cfg[scope_key][scope_string] = {}
            self.fill_scope_combo()

    def check(self, *args):
        # TODO: figure out how to implement this from ui
        scope_key, scope_string = None, ''

        if scope_string == '':
            self.user_cfg[''] = self.editor.data
        else:
            self.user_cfg[scope_key][scope_string] = self.editor.data
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
