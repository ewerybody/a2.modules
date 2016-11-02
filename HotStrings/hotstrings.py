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
        self.user_cfg = user_cfg
        print('self.user_cfg:')
        pprint(self.user_cfg)
        self.fill_items(self.user_cfg.get('value', {}).keys())
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
        self._config_widgets['scope'] = self.ui.scope

        self.ui.scope_field = QtGui.QLineEdit(self)
        self.ui.scope_field.setObjectName('scope_field')
        self._config_widgets['scope_field'] = self.ui.scope_field

        for widget in self._config_widgets.values():
            self.ui.config_layout.addWidget(widget)

        a2ctrl.connect.control_list(self._config_widgets.values(), self._current_cfg, self._cfg_changed)

        spacer = QtGui.QSpacerItem(0, 0, QtGui.QSizePolicy.Minimum, QtGui.QSizePolicy.Expanding)
        self.ui.config_layout.addItem(spacer)

        self._cfg_changed.connect(self.update_config)

        self.selected_text_changed.connect(self.fill_data)

    def update_config(self):
        diff_dict = {}
        for key, value in self._current_cfg.items():
            if value != default_dict[key]:
                diff_dict[key] = value
        if diff_dict:
            self.user_cfg[self.selected_text] = diff_dict
        elif self.selected_text in self.user_cfg:
            del self.user_cfg[self.selected_text]
        self.hotstring_changed.emit()

    def fill_data(self, item):
        print('item: %s' % item)
        print('item in self.user_cfg: %s' % (item in self.user_cfg))
        cfg = self.user_cfg.get(item, default_dict)

        for name, widget in self._config_widgets.items():
            value = cfg.get(name, default_dict[name])
            if isinstance(default_dict[name], bool):
                widget.setChecked(value)


class Draw(DrawCtrl):
    """
    The frontend widget visible to the user with options
    to change the default behavior of the element.
    """
    def __init__(self, main, cfg, mod):
        cfg.setdefault('name', 'user_hotstrings')
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
        print('self.editor.user_cfg: %s' % self.editor.user_cfg)
        self.set_user_value(self.editor.user_cfg.get('value', {}))
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
    pass
