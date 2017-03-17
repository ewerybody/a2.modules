# -*- coding: utf-8 -*-
"""
Some element description ...

@created: 2017 2 10
@author: Eric Werner
"""
import os
import json
from functools import partial

from PySide import QtGui, QtCore

import a2ahk
import a2core
import a2ctrl
from a2element import DrawCtrl, EditCtrl
from a2widget import A2ItemEditor, A2ButtonField, A2CoordsField
from pprint import pprint


DEFAULT_TITLE = '*'
log = a2core.get_logger(__name__)


class SessionRestoreWindowLister(A2ItemEditor):
    #    _cfg_changed = QtCore.Signal(str)

    def __init__(self, cfg, parent):
        self.draw_ctrl = parent
        self.data = cfg or {}
        super(SessionRestoreWindowLister, self).__init__(parent=parent)

        self._process_menu = QtGui.QMenu(self)

        # TODO: thread it
        self._fetch_window_process_list()
        labels = ['Process Name', 'Window Title', 'Window Class', 'Position', 'Size', '']

        self.ui.proc_field = QtGui.QLineEdit()
        self.ui.proc_field.setEnabled(False)
        #self.ui.title_field.field.setPlaceholderText(labels[0])
        self.add_data_widget('process', self.ui.proc_field, self.ui.proc_field.setText,
                             default_value='', label=labels[0])

        self.ui.title_field = A2ButtonField()
        self.add_data_widget('title', self.ui.title_field, self.ui.title_field.setText,
                             default_value=DEFAULT_TITLE, label=labels[1])

        self.ui.class_field = A2ButtonField()
        self.add_data_widget('class', self.ui.class_field, self.ui.class_field.setText,
                             default_value='*', label=labels[2])

        self.ui.pos_field = A2CoordsField()
        self.ui.size_field = A2CoordsField()

        self.add_data_widget('xy', self.ui.pos_field, self.ui.pos_field.set_value, default_value=(0, 0),
                             label='Coordinates')
        self.add_data_widget('wh', self.ui.size_field, self.ui.size_field.set_value, default_value=(0, 0),
                             label='Window Size')

        self.ui.ignore_check = QtGui.QCheckBox('Ignore this Window')
        self.add_data_widget('ignore', self.ui.ignore_check, self.ui.ignore_check.setChecked,
                             default_value=False)

        self.ui.some_button = QtGui.QPushButton('some button')
        self.ui.some_button.clicked.connect(self.some_function)
        self.ui.config_layout.setWidget(self.ui.config_layout.rowCount(), QtGui.QFormLayout.FieldRole,
                                        self.ui.some_button)

        action = QtGui.QAction('Set to exactly "" No Title', self.ui.title_field.menu,
                               triggered=partial(self.ui.title_field.setText, ''))
        self.ui.title_field.add_action(action)
        action = QtGui.QAction('Set to "*" Any Title', self.ui.title_field.menu,
                               triggered=partial(self.ui.title_field.setText, '*'))
        self.ui.title_field.add_action(action)
        action = QtGui.QAction('Insert ".*" Wildcard', self.ui.title_field.menu,
                               triggered=partial(self.ui.title_field.insert, '.*'))
        self.ui.title_field.add_action(action)
        self.title_menu = QtGui.QMenu('Available Titles')
        self.title_menu.aboutToShow.connect(self._build_title_menu)
        self.ui.title_field.menu.addMenu(self.title_menu)

        action = QtGui.QAction('Set to "*" Any Class', self.ui.class_field.menu,
                               triggered=partial(self.ui.class_field.setText, '*'))
        self.ui.class_field.add_action(action)
        action = QtGui.QAction('Insert ".*" Wildcard', self.ui.class_field.menu,
                               triggered=partial(self.ui.class_field.insert, '.*'))
        self.ui.class_field.add_action(action)
        self.class_menu = QtGui.QMenu('Available Class Names')
        self.class_menu.aboutToShow.connect(self._built_classes_menu)
        self.ui.class_field.menu.addMenu(self.class_menu)

    def _built_classes_menu(self):
        self.class_menu.clear()
        process_name = self.data[self.selected_name]['process']
        for class_name in set([win[0] for win in self._fetch_window_data(process_name)]):
            action = QtGui.QAction(class_name, self, triggered=partial(self.ui.class_field.setText, class_name))
            self.class_menu.addAction(action)

    def _build_title_menu(self):
        self.title_menu.clear()
        process_name = self.data[self.selected_name]['process']
        for title in set([win[1] for win in self._fetch_window_data(process_name) if win[1]]):
            action = QtGui.QAction(title, self, triggered=partial(self.ui.title_field.setText, title))
            self.title_menu.addAction(action)

    def some_function(self):
        process_name = self.data[self.selected_name]['process']
        win_data = self._fetch_window_data(process_name)
        pprint(win_data)

    def _fetch_window_data(self, process_name):
        this_path = self.draw_ctrl.mod.path
        cmd = '%s' % os.path.join(this_path, 'sessionrestore_get_windows.ahk')
        window_data_str = a2ahk.call_cmd(cmd, process_name, cwd=this_path)
        print('window_data_str: "%s"' % window_data_str)
        try:
            window_data = json.loads(window_data_str)
            return window_data
        except Exception as error:
            log.error('Could not get JSON data from window data string:\n  %s' % window_data_str)
            log.error(error)
        return []

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
        # for now we're just filling with the data of 1st found window
        win_data = self._fetch_window_data(name)[0]

        new_name = a2core.get_next_free_number(name, self.data.keys(), ' ')
        item = self._add_and_setup_item(new_name)
        self.data[new_name] = {'process': name,
                               'class': win_data[0],
                               'title': win_data[1],
                               'xy': (win_data[2], win_data[3]),
                               'wh': (win_data[4], win_data[5])}

        a2ctrl.qlist.select_items(self.ui.item_list, item)
        self.data_changed.emit()

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
    window_list = []
    for data in user_cfg.values():
        xy, wh = data.get('xy', (0, 0)), data.get('wh', (0, 0))
        window_list.append([data['process'], data.get('class', ''),
                            data.get('title', DEFAULT_TITLE),
                            xy[0], xy[1], wh[0], wh[1],
                            data.get('ignore', False)])
    db_dict['variables']['SessionRestore_List'] = window_list
