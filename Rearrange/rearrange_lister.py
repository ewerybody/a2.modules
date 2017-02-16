# -*- coding: utf-8 -*-
"""
Some element description ...

@created: 2017 2 10
@author: Eric Werner
"""
import a2ctrl
from PySide import QtGui, QtCore
from a2element import DrawCtrl, EditCtrl
from a2widget import A2ItemEditor
import ahk
from functools import partial


class SessionRestoreWindowLister(A2ItemEditor):
#    _cfg_changed = QtCore.Signal(str)
#    hotstring_changed = QtCore.Signal()

    def __init__(self, user_cfg, parent):
        super(SessionRestoreWindowLister, self).__init__(parent)
        self._process_menu = QtGui.QMenu(self)

        # TODO: thread it
        self._fetch_window_process_list()

    def _fetch_window_process_list(self):
        scope_nfo = ahk.call_lib_cmd('get_scope_nfo')
        scope_nfo = scope_nfo.split('\\n')
        if not scope_nfo:
            log.error('Error getting scope_nfo!! scope_nfo: %s' % scope_nfo)
            return

        processes = set()
        num_items = len(scope_nfo)
        num_items = num_items - (num_items % 3)
        for i in range(0, num_items, 3):
            if scope_nfo[i + 2]:
                processes.add(scope_nfo[i + 2])
        self._process_list = sorted(processes, key=lambda x: x.lower())

        for name in self._process_list:
            action = QtGui.QAction(name, self, triggered=partial(self.add_process, name))
            self._process_menu.addAction(action)

    def add_process(self, name):
        item = self._add_and_setup_item(name)
        # current_items.append(new_item_name)
        a2ctrl.qlist.select_items(self.ui.item_list, item)

    def add_item(self):
        self._process_menu.popup(QtGui.QCursor.pos())


class Draw(DrawCtrl):
    """
    The frontend widget visible to the user with options
    to change the default behavior of the element.
    """
    def __init__(self, main, cfg, mod):
        super(Draw, self).__init__(main, cfg, mod)
        self.layout = QtGui.QVBoxLayout(self)
        self.editor = SessionRestoreWindowLister(self.user_cfg, self)
        #self.editor.hotstring_changed.connect(self.delayed_check)
        self.layout.addWidget(self.editor)
        self.setLayout(self.layout)


class Edit(EditCtrl):
    """
    The background widget that sets up how the user can edit the element,
    visible when editing the module.
    """
    def __init__(self, cfg, main, parentCfg):
        super(Edit, self).__init__(cfg, main, parentCfg)

    @staticmethod
    def element_name():
        """The elements display name shown in UI"""
        return 'Rearrange_Lister'

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
