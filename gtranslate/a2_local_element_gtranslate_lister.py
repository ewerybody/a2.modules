"""
A lister element for creating arbitrary translation hotkeys.
"""
import os
import sys
from copy import deepcopy

from PySide6 import QtWidgets, QtCore

import a2ctrl
import a2widget.a2hotkey
import a2element.hotkey
from a2element import DrawCtrl, EditCtrl
from a2widget import a2item_editor, a2input_dialog, a2hotkey

THIS_DIR = os.path.abspath(os.path.dirname(__file__))
if THIS_DIR not in sys.path:
    sys.path.append(THIS_DIR)
import gtranslate_langs


_DEFAULT_HOTKEY = {
    'disablable': True,
    'enabled': True,
    'functionCode': '',
    'functionMode': 0,
    'key': [''],
    'keyChange': True,
    'label': '...',
    'multiple': True,
    'name': 'some_name',
    'scope': [],
    'scopeChange': False,
    'scopeMode': 0,
    'typ': 'hotkey',
}


class GTranslateLister(a2item_editor.A2ItemEditor):
    def __init__(self, cfg, parent):
        super(GTranslateLister, self).__init__(parent)
        self.item_flags = (
            QtCore.Qt.ItemIsSelectable | QtCore.Qt.ItemIsDragEnabled | QtCore.Qt.ItemIsEnabled
        )
        self.set_data(cfg)

        self._hk_user_cfg = {}
        hk_config = deepcopy(_DEFAULT_HOTKEY)
        self._dummymod = _ModStub(hk_config)
        self.hotkey = a2element.hotkey.Draw(self, hk_config, self._dummymod, self._hk_user_cfg)
        self.add_row(self.hotkey)
        self.selected_name_changed.connect(self._update_hotkey)

        self.hotkey.hotkey_button.hotkey_changed.connect(self._changed)
        self.hotkey.hotkey_button.scope_changed.connect(self._changed)
        self.hotkey.checkbox.clicked.connect(self._changed)

        if cfg:
            self.ui.item_list.select_names([sorted(cfg.keys())[0]])

    def add_item(self):
        dialog = NewDialog(self, self.data.keys())
        dialog.okayed.connect(self._add)
        dialog.show()

    def _add(self):
        key = self.sender().output
        self.add_named_item(key)
        if key not in self.data:
            self._changed()

    def _update_hotkey(self, name):
        try:
            from_lang, to_lang = name.split(gtranslate_langs.SEPARATOR)
        except ValueError:
            return

        text = 'Translate "%s" to "%s"' % (
            gtranslate_langs.key_to_name(from_lang),
            gtranslate_langs.key_to_name(to_lang),
        )
        self.hotkey.label.setText(text)
        this_cfg = self.data.get(name, {})
        self.hotkey.checkbox.blockSignals(True)
        self.hotkey.hotkey_button.blockSignals(True)
        self.hotkey.hotkey_button.set_config(this_cfg)
        self.hotkey.checkbox.setChecked(this_cfg.get('enabled', True))
        self.hotkey.checkbox.blockSignals(False)
        self.hotkey.hotkey_button.blockSignals(False)

    def _changed(self):
        self.data[self.selected_name] = self.hotkey.get_user_dict()
        self.data_changed.emit()

    def set_list_width(self, value):
        self.ui.list_layout_widget.setMaximumWidth(value)


class _ModStub:
    """A fake module to be able to receive element changes."""

    def __init__(self, config):
        self.config = config
        self.enabled = False

    def set_user_cfg(self, cfg, this, name):
        cfg[name] = this

    def change(self):
        pass


class NewDialog(a2input_dialog.A2ConfirmDialog):
    """Dialog to select the languages to translate between."""

    okayed = QtCore.Signal(str)
    field_changed = QtCore.Signal(str)

    def __init__(self, parent, present_keys):
        super(NewDialog, self).__init__(
            parent, 'New gtranslate Hotkey', 'Select languages to translate between:'
        )
        self._present_keys = present_keys

        self.ui.combo_from = QtWidgets.QComboBox(self)
        self.ui.combo_from.addItem(gtranslate_langs.AUTO_LANGUAGE)
        self.ui.combo_from.setItemData(0, gtranslate_langs.AUTO_KEY)

        self.ui.combo_to = QtWidgets.QComboBox(self)
        for i, (name, key) in enumerate(self.iter_langs()):
            self.ui.combo_from.addItem(f'{name} ({key})')
            self.ui.combo_from.setItemData(i + 1, key)
            self.ui.combo_to.addItem(f'{name} ({key})')
            self.ui.combo_to.setItemData(i, key)

        if gtranslate_langs.DEFAULT_TRANSLATION not in self._present_keys:
            name = gtranslate_langs.key_to_name(gtranslate_langs.DEFAULT)
            self.ui.combo_to.setCurrentText(f'{name} ({gtranslate_langs.DEFAULT})')

        self.ui.combo_from.currentIndexChanged.connect(self.check)
        self.ui.combo_to.currentIndexChanged.connect(self.check)
        self.ui.combo_to.setFocus()

        form = QtWidgets.QFormLayout()
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
            key = f'{from_lang}{gtranslate_langs.SEPARATOR}{to_lang}'
        return key

    def iter_langs(self):
        for name, key in gtranslate_langs.get().items():
            yield name, key


class Draw(DrawCtrl):
    """
    The frontend widget visible to the user with options
    to change the default behavior of the element.
    """

    def __init__(self, *args):
        super(Draw, self).__init__(*args)
        self.main_layout = QtWidgets.QVBoxLayout(self)
        self.main_layout.setContentsMargins(0, 0, 0, 0)

        self.editor = GTranslateLister(self.user_cfg, self)
        self.editor.data_changed.connect(self.delayed_check)
        self.main_layout.addWidget(self.editor)

        self.is_expandable_widget = True
        self.editor.set_list_width(self.main.style.scale(120))

    def check(self):
        self.user_cfg = self.editor.data
        self.set_user_value(self.user_cfg)
        self.change()


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
    """FIXME: This is currently quite a copy of the hotkey element get_settings.
    In future this needs to be some sort of make_hotkey-function...
    Not stuffing data into a dict like this :/.
    """
    for translation_name, translation_cfg in user_cfg.items():
        Vars = a2widget.a2hotkey.Vars
        if not translation_cfg.get('enabled', False):
            continue

        key = a2ctrl.get_cfg_value(cfg, translation_cfg, 'key')
        scope = a2ctrl.get_cfg_value(cfg, translation_cfg, Vars.scope, list)
        scope_mode = a2ctrl.get_cfg_value(cfg, translation_cfg, Vars.scope_mode, int)
        try:
            from_lang, to_lang = translation_name.split(gtranslate_langs.SEPARATOR)
        except ValueError:
            continue
        func = f'gtranslate("{from_lang}", "{to_lang}")'

        db_dict.setdefault('hotkeys', {})
        db_dict['hotkeys'].setdefault(scope_mode, [])
        # save a global if global scope set or all-but AND scope is empty
        if scope_mode == 0 or scope_mode == 2 and scope == '':
            db_dict['hotkeys'][0].append([key, func])
        else:
            db_dict['hotkeys'][scope_mode].append([scope, key, func])
