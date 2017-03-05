# -*- coding: utf-8 -*-
"""
Some element description ...

@created: 2017 2 10
@author: Eric Werner
"""
from pprint import pprint
from functools import partial

from PySide import QtGui, QtCore

import a2ahk
import a2core
import a2ctrl
from a2element import DrawCtrl, EditCtrl
from a2widget import A2ItemEditor


log = a2core.get_logger(__name__)
default_dict = {'title': '', 'class': '', 'x': 0, 'y': 0, 'w': 0, 'h': 0, 'ignore': False}


class SessionRestoreWindowLister(A2ItemEditor):
    #    _cfg_changed = QtCore.Signal(str)

    def __init__(self, cfg, parent):
        self.data = cfg or {}
        super(SessionRestoreWindowLister, self).__init__(parent=parent)

        self._process_menu = QtGui.QMenu(self)

        # TODO: thread it
        self._fetch_window_process_list()
        labels = ['Window Title', 'Window Class', 'Position', 'Size', '']

        # self.ui.title_field = ButtonField()
        self.ui.title_field = QtGui.QLineEdit()
        #self.ui.title_field.field.setPlaceholderText(labels[0])
        self.add_data_widget('title', self.ui.title_field, self.ui.title_field.setText,
                             default_value='', label=labels[0])

        #self.ui.class_field = ButtonField()
        #self.ui.class_field.field.setPlaceholderText(labels[1])
        self.ui.class_field = QtGui.QLineEdit()
        self.add_data_widget('class', self.ui.class_field, self.ui.class_field.setText,
                             default_value='', label=labels[1])

        for axis, label_idx in [('x', 2), ('y', 2), ('w', 3), ('h', 3)]:
            widget = QtGui.QSpinBox()
            self.add_data_widget(axis, widget, widget.setValue, default_value=0,
                                 label='%s %s' % (labels[label_idx], axis.upper()))

        self.ui.ignore_check = QtGui.QCheckBox('Ignore this Window')
        self.add_data_widget('ignore', self.ui.ignore_check, self.ui.ignore_check.setChecked,
                             default_value=False)

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
        num_items -= num_items % 3
        for i in range(0, num_items, 3):
            if scope_nfo[i + 2]:
                processes.add(scope_nfo[i + 2])
        self._process_list = sorted(processes, key=lambda x: x.lower())

        for name in self._process_list:
            action = QtGui.QAction(name, self, triggered=partial(self.add_process, name))
            self._process_menu.addAction(action)

    def add_process(self, name):
        new_name = a2core.get_next_free_number(name, self.data.keys(), ' ')
        item = self._add_and_setup_item(new_name)
        self.data[new_name] = {}
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
        self.main_layout = QtGui.QVBoxLayout(self)
        self.main_layout.setContentsMargins(0, 0, 0, 0)
        self.editor = SessionRestoreWindowLister(self.user_cfg, self)
        self.editor.data_changed.connect(self.delayed_check)
        self.main_layout.addWidget(self.editor)
        self.is_expandable_widget = True

    def check(self, *args):
        super(Draw, self).check()
        pprint(self.editor.data)
        self.set_user_value(self.editor.data)
        self.change()


class Edit(EditCtrl):
    def __init__(self, cfg, main, parent_cfg):
        super(Edit, self).__init__(cfg, main, parent_cfg)

    @staticmethod
    def element_name():
        """The elements display name shown in UI"""
        return 'Rearrange_Lister'

    @staticmethod
    def element_icon():
        return a2ctrl.Icons.inst().check


class ButtonField(QtGui.QWidget):
    changed = QtCore.Signal(str)

    def __init__(self):
        super(ButtonField, self).__init__()
        self.h_layout = QtGui.QHBoxLayout(self)
        self.h_layout.setContentsMargins(0, 0, 0, 0)

        self.field = QtGui.QLineEdit(self)
        self.h_layout.addWidget(self.field)

        self.button = QtGui.QPushButton(self)
        self.button.setMaximumSize(45, 45)
        self.h_layout.addWidget(self.button)

    def set_value(self, this):
        print('this: %s' % this)


class CoordsField(QtGui.QWidget):
    changed = QtCore.Signal(tuple)

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

    def set_value(self, this):
        print('this: %s' % this)


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
