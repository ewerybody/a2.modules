"""
Some element description ...

@created: 2016 9 24
@author: eRiC
"""
import a2ctrl
from PySide import QtGui
from a2element import DrawCtrl, EditCtrl
from a2widget.a2item_editor import A2ItemEditor


class Draw(DrawCtrl):
    """
    The frontend widget visible to the user with options
    to change the default behavior of the element.
    """
    def __init__(self, main, cfg, mod):
        super(Draw, self).__init__(main, cfg, mod)
        self._setupUi()

    def _setupUi(self):
        self.layout = QtGui.QVBoxLayout(self)
        self.item_editor = A2ItemEditor(self)
        self.layout.addWidget(self.item_editor)
        self.setLayout(self.layout)


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
