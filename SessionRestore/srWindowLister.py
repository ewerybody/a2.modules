# -*- coding: utf-8 -*-
"""
Some element description ...

@created: 2017 2 10
@author: Eric Werner
"""
from functools import partial
from collections import OrderedDict

from PySide import QtGui, QtCore

import a2ahk
import a2ctrl
from a2element import DrawCtrl, EditCtrl
from a2widget import A2ItemEditor
import a2core


default_dict = {'title': '', 'class': '', 'x': 0, 'y': 0, 'w': 0, 'h': 0, 'ignore': False}


class SessionRestoreWindowLister(A2ItemEditor):
    #    _cfg_changed = QtCore.Signal(str)

    def __init__(self, cfg, parent):
        self.data = cfg or {}
        super(SessionRestoreWindowLister, self).__init__(parent=parent)

        self._process_menu = QtGui.QMenu(self)

        # TODO: thread it
        self._fetch_window_process_list()
        self.selected_name_changed.connect(self.draw_data)

        self._config_widgets = OrderedDict()
        labels = ['Window Title', 'Window Class', 'Position', 'Size', '']

        self.ui.title_field = ButtonField()
        self.ui.title_field.field.setPlaceholderText(labels[0])
        self.ui.config_layout.addWidget(self.ui.title_field)

        self.ui.class_field = ButtonField()
        self.ui.class_field.field.setPlaceholderText(labels[1])
        self.ui.config_layout.addWidget(self.ui.class_field)

        self.ui.coords_field = CoordsField()
        self.ui.config_layout.addWidget(self.ui.coords_field)

        self.ui.size_field = CoordsField()
        self.ui.config_layout.addWidget(self.ui.size_field)

        spacer = QtGui.QSpacerItem(0, 0, QtGui.QSizePolicy.Minimum, QtGui.QSizePolicy.Expanding)
        self.ui.config_layout.addItem(spacer)

    def _fetch_window_process_list(self):
        scope_nfo = a2ahk.call_lib_cmd('get_scope_nfo')
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
        new_name = a2core.get_next_free_number(name, self.cfg.keys(), ' ')
        item = self._add_and_setup_item(new_name)
        self.cfg[new_name] = [name, '', '', 0, 0, 0, 0, False]
        # current_items.append(new_item_name)
        a2ctrl.qlist.select_items(self.ui.item_list, item)

    def add_item(self):
        self._process_menu.popup(QtGui.QCursor.pos())

    def draw_data(self, item_name):
        self._drawing = True
        cfg = self.cfg.get(item_name, default_dict)

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


class Draw(DrawCtrl):
    """
    The frontend widget visible to the user with options
    to change the default behavior of the element.
    """
    def __init__(self, main, cfg, mod):
        super(Draw, self).__init__(main, cfg, mod)
        self.main_layout = QtGui.QVBoxLayout(self)
        self.main_layout.setContentsMargins(0, 0, 0, 0)
        self.editor = SessionRestoreWindowLister(self.user_cfg, self)
        self.main_layout.addWidget(self.editor)
        self.is_expandable_widget = True


class Edit(EditCtrl):
    def __init__(self, cfg, main, parentCfg):
        super(Edit, self).__init__(cfg, main, parentCfg)

    @staticmethod
    def element_name():
        """The elements display name shown in UI"""
        return 'Rearrange_Lister'

    @staticmethod
    def element_icon():
        return a2ctrl.Icons.inst().check


class ButtonField(QtGui.QWidget):
    def __init__(self):
        super(ButtonField, self).__init__()
        self.h_layout = QtGui.QHBoxLayout(self)
        self.h_layout.setContentsMargins(0, 0, 0, 0)

        self.field = QtGui.QLineEdit(self)
        self.h_layout.addWidget(self.field)

        self.button = QtGui.QPushButton(self)
        self.button.setMaximumSize(45, 45)
        self.h_layout.addWidget(self.button)


class CoordsField(QtGui.QWidget):
    def __init__(self):
        super(CoordsField, self).__init__()
        self.h_layout = QtGui.QHBoxLayout(self)
        self.h_layout.setContentsMargins(0, 0, 0, 0)

        self.x_field = QtGui.QSpinBox(self)
        self.y_field = QtGui.QSpinBox(self)
        self.h_layout.addWidget(self.x_field)
        self.h_layout.addWidget(self.y_field)

        self.button = QtGui.QPushButton(self)
        self.button.setMaximumSize(45, 45)
        self.h_layout.addWidget(self.button)


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
    db_dict['variables']['SessionRestore_List'] = ["value"]
