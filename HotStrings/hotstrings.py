"""
Some element description ...

@created: 2016 9 24
@author: eRiC
"""
import os
import a2ctrl
from PySide import QtGui, QtCore
from a2element import DrawCtrl, EditCtrl
from a2widget.a2item_editor import A2ItemEditor
from a2widget.textfield_autoheight import TextField_AutoHeight
from collections import OrderedDict
from pprint import pprint


hs_checkboxes = [
    # key, label
    ('instant', 'Triggered Immediately (otherwise by Space, Enter ...)'),
    ('ignore', 'Ignore Characters Causing Replacement'),
    ('inside', 'Replace Inside Words'),
    ('append', 'Don\'t Replace Abbreviation, Just append'),
    ('raw', 'Output Control-Characters as Plain Text (like {Enter})'),
    ('substitute', 'substitute !, +, ^, and # with Alt, Shift, Ctrl or Windows'),
    ('cmdmode', 'Autohotkey Command Mode'),
    ('sendplay', 'SendPlay Mode')]
default_dict = dict([(name, False) for name, _ in hs_checkboxes])
default_dict.update({'case': 0, 'scope': 0, 'text': '', 'scope_field': ''})


class HotStringsEditor(A2ItemEditor):
    _cfg_changed = QtCore.Signal(str)
    hotstring_changed = QtCore.Signal()

    def __init__(self, user_cfg, parent):
        super(HotStringsEditor, self).__init__(parent)
        self._drawing = True
        self.user_cfg = user_cfg
        print('self.user_cfg:')
        pprint(self.user_cfg)
        self.fill_items(sorted(self.user_cfg.keys(), key=lambda s: s[0].lower()))

        self._current_cfg = {}
        self._config_widgets = OrderedDict()

        self.ui.text = TextField_AutoHeight(self)
        self.ui.text.setObjectName('text')
        self._config_widgets['text'] = self.ui.text

        for name, label in hs_checkboxes:
            checkbox = QtGui.QCheckBox(self)
            checkbox.setText(label)
            checkbox.setObjectName(name)
            self._config_widgets[name] = checkbox

        self.ui.case = QtGui.QComboBox(self)
        self.ui.case.setObjectName('case')
        self.ui.case.addItems(['Ignore Case', 'Case Sensitive', 'Don\'t Conform To Typed Case'])
        self._config_widgets['case'] = self.ui.case

        self.ui.scope = QtGui.QComboBox(self)
        self.ui.scope.setObjectName('scope')
        self.ui.scope.addItems(['Scope: Global', 'Scope: Only In:', 'Scope: Not In:'])
        self.ui.scope.currentIndexChanged.connect(self.toggle_scope_field)
        self._config_widgets['scope'] = self.ui.scope

        self.ui.scope_field = QtGui.QLineEdit(self)
        self.ui.scope_field.setObjectName('scope_field')
        self._config_widgets['scope_field'] = self.ui.scope_field

        for widget in self._config_widgets.values():
            self.ui.config_layout.addWidget(widget)

        a2ctrl.connect.control_list(self._config_widgets.values(), self._current_cfg, self._cfg_changed)
        self._cfg_changed.connect(self.update_config)

        spacer = QtGui.QSpacerItem(0, 0, QtGui.QSizePolicy.Minimum, QtGui.QSizePolicy.Expanding)
        self.ui.config_layout.addItem(spacer)

        self.selected_name_changed.connect(self.draw_data)
        self.item_changed.connect(self.item_rename)
        self.item_deleted.connect(self.item_remove)
        self._drawing = False

    def item_rename(self, item_tuple):
        old_name, new_name, _item = item_tuple
        print('item_rename: %s > %s' % (old_name, new_name))
        data = self.user_cfg.pop(old_name)
        self.user_cfg[new_name] = data
        self.hotstring_changed.emit()

    def item_remove(self, name):
        print('item_remove: %s' % name)
        self.user_cfg.pop(name)
        print('name in self.user_cfg: %s' % (name in self.user_cfg))
        self.hotstring_changed.emit()

    def update_config(self):
        if self._drawing:
            return

        print('update_config...')
        diff_dict = {}
        for key, value in self._current_cfg.items():
            if value != default_dict[key]:
                diff_dict[key] = value
        self.user_cfg[self.selected_name] = diff_dict
        self.hotstring_changed.emit()

    def draw_data(self, item):
        self._drawing = True
        print('%s in self.user_cfg: %s' % (item, (item in self.user_cfg)))
        cfg = self.user_cfg.get(item, default_dict)

        for name, widget in self._config_widgets.items():
            value = cfg.get(name, default_dict[name])
            if isinstance(default_dict[name], bool):
                widget.setChecked(value)
            elif isinstance(default_dict[name], str):
                widget.setText(value)
            elif isinstance(default_dict[name], int):
                widget.setCurrentIndex(value)

            if name == 'scope':
                self.toggle_scope_field(value)

        self._drawing = False

    def toggle_scope_field(self, index):
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
        self._setupUi()

        hs_ahk = os.path.join(self.a2.paths.settings, 'hotstrings.ahk')
        print('hs_ahk: exists %s - %s' % (os.path.exists(hs_ahk), hs_ahk))

    def _setupUi(self):
        self.layout = QtGui.QVBoxLayout(self)
        self.editor = HotStringsEditor(self.userCfg or {}, self)
        self.editor.hotstring_changed.connect(self.delayed_check)
        self.layout.addWidget(self.editor)
        self.setLayout(self.layout)

    def check(self, *args):
        DrawCtrl.check(self, *args)
        print('self.editor.user_cfg:')
        pprint(self.editor.user_cfg)
        self.set_user_value(self.editor.user_cfg)
        self.change()


class Edit(EditCtrl):
    """
    The background widget that sets up how the user can edit the element,
    visible when editing the module.
    """
    def __init__(self, cfg, main, parentCfg):
        super(Edit, self).__init__(cfg, main, parentCfg, addLayout=False)

    @staticmethod
    def element_name():
        """The elements display name shown in UI"""
        return 'Hotstrings'

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
    stuff = a2ctrl.get_cfg_value(cfg, user_cfg, typ=dict, default={})
    print('get_settings stuff:')
    pprint(stuff)
