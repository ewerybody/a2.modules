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


print('__file__: %s' % __file__)
this_dir = os.path.dirname(__file__)
if this_dir not in sys.path:
    sys.path.append(this_dir)
import hotstrings_io


HOTSTRINGS_FILENAME = 'hotstrings.ahk'
hs_checkboxes = [
    # key, label
    ('instant', 'Triggered Immediately (otherwise by Space, Enter ...)'),
    ('ignore', 'Ignore Characters Causing Replacement'),
    ('inside', 'Replace Inside Words'),
    ('append', 'Don\'t Replace Abbreviation, Just append'),
    ('raw', 'Output Control-Characters as Plain Text (like {Enter})'),
    ('textmode', 'Text mode - Sends replacement text raw'),
    ('origmode', 'Let !, +, ^, # throw Alt, Shift, Ctrl, Win keystrokes')]
    # ('cmdmode', 'Autohotkey Command Mode'),


class HotStringsEditor(A2ItemEditor):

    def __init__(self, user_cfg, parent):

        self.data = user_cfg
        self.draw_labels = False

        super(HotStringsEditor, self).__init__(parent)

        self.ui.text = A2TextField(self)
        self.add_data_widget('text', self.ui.text, self.ui.text.setText, self.ui.text.editing_finished,
                             default_value='')

        for name, label in hs_checkboxes:
            checkbox = QtWidgets.QCheckBox(self)
            checkbox.setText(label)
            self.add_data_widget(name, checkbox, checkbox.setChecked,
                                 default_value=False)

        # WIP: not done yet!
        self.ui.sendmode = QtWidgets.QComboBox(self)
        self.ui.sendmode.setEnabled(False)
        self.ui.sendmode.addItems(['SendEvent', 'SendInput', ' SendPlay'])
        self.add_data_label_widget('sendmode', self.ui.sendmode, self.ui.sendmode.setCurrentIndex,
                                   default_value=0, label='Send Mode')

        self.ui.case = QtWidgets.QComboBox(self)
        self.ui.case.addItems(['Forward to text', 'Sensitive', 'Keep original'])
        self.add_data_label_widget('case', self.ui.case, self.ui.case.setCurrentIndex,
                                   default_value=0)

        # WIP: not done yet!
        self.ui.scope = QtWidgets.QComboBox(self)
        self.ui.scope.setEnabled(False)
        self.ui.scope.addItems(['Scope: Global', 'Scope: Only In:', 'Scope: Not In:'])
        self.ui.scope.currentIndexChanged.connect(self.toggle_scope_field)
        self.add_data_label_widget('scope', self.ui.scope, self.ui.scope.setCurrentIndex,
                                   default_value=0)
        self.ui.scope_field = QtWidgets.QLineEdit(self)
        self.ui.scope_field.setVisible(False)
        self.add_data_widget('scope_field', self.ui.scope_field, self.ui.scope_field.setText,
                             default_value='')

        spacer = QtWidgets.QSpacerItem(0, 0, QtWidgets.QSizePolicy.Minimum, QtWidgets.QSizePolicy.Expanding)
        self.ui.config_layout.addItem(spacer)

    def toggle_scope_field(self, index=None):
        """only show the scope field if not global"""
        self.ui.scope_field.setVisible(index != 0)


class Draw(DrawCtrl):
    """
    The frontend widget visible to the user with options
    to change the default behavior of the element.
    """
    def __init__(self, main, cfg, mod):
        cfg.setdefault('name', 'hotstrings')
        super(Draw, self).__init__(main, cfg, mod)
        self._hs_code_b4 = None
        self._setupUi()
        self.is_expandable_widget = True
        self._hotstrings_ahk_path = os.path.join(self.a2.paths.settings, HOTSTRINGS_FILENAME)

    def _setupUi(self):
        self.main_layout = QtWidgets.QVBoxLayout(self)
        self.main_layout.setContentsMargins(0, 0, 0, 0)
        self.editor = HotStringsEditor(self.user_cfg, self)
        self.editor.data_changed.connect(self.delayed_check)
        self.main_layout.addWidget(self.editor)

    def check(self, *args):
        self.set_user_value(self.editor.data)

        hotstrings_code = hotstrings_io.dict_to_hotstrings(self.editor.data)
        if hotstrings_code == self._hs_code_b4:
            return
        self._hs_code_b4 = hotstrings_code

        hotstrings_code = a2runtime.EDIT_DISCLAIMER % 'hotstrings' + '\n' + hotstrings_code
        a2util.write_utf8(self._hotstrings_ahk_path, hotstrings_code)

        self.change()


class Edit(EditCtrl):
    def __init__(self, *args):
        super(Edit, self).__init__(*args)
        self.mainLayout.addWidget(QtWidgets.QLabel('Nothing to setup on the HotStrings element.'
                                                   'This one is all for the user.'))

    @staticmethod
    def element_name():
        """The elements display name shown in UI"""
        return 'Hotstrings'

    @staticmethod
    def element_icon():
        return a2ctrl.Icons.inst().hotkey


def get_settings(module_key, cfg, db_dict, user_cfg):
    """
    So far this only adds the hotstrings.ahk to includes.
    """
    db_dict.setdefault('settings_includes', []).append(HOTSTRINGS_FILENAME)
