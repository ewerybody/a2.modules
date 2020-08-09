"""
Some element description ...

@created: 2020 6 30
@author: eric
"""
import os, sys

from PySide2 import QtWidgets, QtCore

import a2ctrl
import a2util
from a2element import DrawCtrl, EditCtrl
from a2widget import a2item_editor, a2input_dialog, a2hotkey



class GTranslateLister(a2item_editor.A2ItemEditor):
    def __init__(self, cfg, parent):
        super(GTranslateLister, self).__init__(parent)

        hotkey = a2hotkey.A2Hotkey(self)
        self.add_data_widget('hotkey', hotkey, hotkey.set_key)
        ignore_check = QtWidgets.QCheckBox(self)
        ignore_check.setText('Ignore this one')
        self.add_data_widget('ignore', ignore_check, ignore_check.setChecked, default_value=False)


    def add_item(self):
        dialog = NewDialog(self)
        dialog.okayed.connect(self._add)
        dialog.show()

    def _add(self):
        key = self.sender().output
        self.add_named_item(key)


class NewDialog(a2input_dialog.A2ConfirmDialog):
    okayed = QtCore.Signal(str)
    field_changed = QtCore.Signal(str)

    def __init__(self, parent):
        super(NewDialog, self).__init__(
            parent, 'New gtranslate Hotkey', 'Select languaged to translate between:')

        self.ui.combo_from = QtWidgets.QComboBox(self)
        self.ui.combo_from.addItem('Detect Language (auto)')
        self.ui.combo_from.setItemData(0, 'auto')

        self.ui.combo_to = QtWidgets.QComboBox(self)
        for i, (name, key) in enumerate(self.iter_langs()):
            self.ui.combo_from.addItem(f'{name} ({key})')
            self.ui.combo_from.setItemData(i + 1, key)
            self.ui.combo_to.addItem(f'{name} ({key})')
            self.ui.combo_to.setItemData(i, key)

        self.ui.combo_from.currentIndexChanged.connect(self.check)
        self.ui.combo_to.currentIndexChanged.connect(self.check)
        self.ui.combo_from.setFocus()

        form = QtWidgets.QFormLayout(self)
        form.addRow('From:', self.ui.combo_from)
        form.addRow('To:', self.ui.combo_to)
        self.ui.main_layout.insertLayout(1, form)

    def check(self, key=None):
        key = self.get_key(key)
        if key not in self.parent().data:
            self.ui.a2ok_button.setEnabled(True)
            self.ui.a2ok_button.setText('OK')
            return True
        else:
            self.ui.a2ok_button.setEnabled(False)
            self.ui.a2ok_button.setText(f'"{key}" is already liste!')
            return False

    @property
    def output(self):
        return self._output

    def okay(self):
        key = self.get_key()
        if self.check(key):
            self._output = key
            self.okayed.emit(key)
            self.accept()

    def get_key(self, key=None):
        if key is None:
            from_lang = self.ui.combo_from.currentData()
            to_lang = self.ui.combo_to.currentData()
            key = f'{from_lang} > {to_lang}'
        return key

    def iter_langs(self):
        THIS_DIR = os.path.abspath(os.path.dirname(__file__))
        if THIS_DIR not in sys.path:
            sys.path.append(THIS_DIR)
        import gtranslate_langs
        for name, key in gtranslate_langs.get().items():
            yield name, key
        sys.path.remove(THIS_DIR)


class Draw(DrawCtrl):
    """
    The frontend widget visible to the user with options
    to change the default behavior of the element.
    """
    def __init__(self, *args):
        super(Draw, self).__init__(*args)
        self.main_layout = QtWidgets.QVBoxLayout(self)
        self.main_layout.setContentsMargins(0, 0, 0, 0)

        self.editor = GTranslateLister({}, self)
        self.editor.data_changed.connect(self.delayed_check)
        self.main_layout.addWidget(self.editor)

        self.is_expandable_widget = True


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
        return 'GTranslateLister'

    @staticmethod
    def element_icon():
        return a2ctrl.Icons.inst().check


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
    pass
