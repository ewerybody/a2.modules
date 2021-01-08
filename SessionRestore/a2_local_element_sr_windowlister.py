"""
A special item editor element to host various app layouts with different desktop dimensions.
"""
import os
import json
from functools import partial

from a2qt import QtWidgets, QtGui

import a2ahk
import a2core
import a2ctrl
from a2element import DrawCtrl, EditCtrl
from a2widget import a2item_editor, a2button_field, a2coords_field


DEFAULT_TITLE = '*'
NO_AVAILABLE_TXT = 'No a available %s for process "%s"'
log = a2core.get_logger(__name__)


class SessionRestoreWindowLister(a2item_editor.A2ItemEditor):
    def __init__(self, cfg, parent):
        self.draw_ctrl = parent
        self.data = cfg or {}
        super(SessionRestoreWindowLister, self).__init__(parent=parent)

        self._process_menu = QtWidgets.QMenu(self)

        labels = ['Process Name', 'Window Title', 'Window Class', 'Position', 'Size', '']
        self.ui.proc_field = QtWidgets.QLineEdit()
        self.ui.proc_field.setEnabled(False)
        self.add_data_label_widget(
            'process',
            self.ui.proc_field,
            self.ui.proc_field.setText,
            default_value='',
            label=labels[0],
        )

        self.ui.title_field = a2button_field.A2ButtonField()
        self.ui.title_field.setPlaceholderText('No Title')
        self.add_data_label_widget(
            'title',
            self.ui.title_field,
            self.ui.title_field.setText,
            default_value=DEFAULT_TITLE,
            label=labels[1],
        )

        self.ui.class_field = a2button_field.A2ButtonField()
        self.add_data_label_widget(
            'class',
            self.ui.class_field,
            self.ui.class_field.setText,
            default_value='*',
            label=labels[2],
        )

        self.ui.pos_field = a2coords_field.A2CoordsField()
        self.ui.size_field = a2coords_field.A2CoordsField()

        self.add_data_label_widget(
            'xy',
            self.ui.pos_field,
            self.ui.pos_field.set_value,
            default_value=(0, 0),
            label='Coordinates',
        )
        self.add_data_label_widget(
            'wh',
            self.ui.size_field,
            self.ui.size_field.set_value,
            default_value=(0, 0),
            label='Window Size',
        )

        self.ui.ignore_check = QtWidgets.QCheckBox('Ignore this Window')
        self.add_data_label_widget(
            'ignore', self.ui.ignore_check, self.ui.ignore_check.setChecked, default_value=False
        )

        self.ui.title_field.add_action(
            'Set to exactly "" No Title', partial(self.ui.title_field.setText, '')
        )
        self.ui.title_field.add_action(
            'Set to "*" Any Title', partial(self.ui.title_field.setText, '*')
        )
        self.ui.title_field.add_action(
            'Insert ".*" Wildcard', partial(self.ui.title_field.insert, '.*')
        )
        self.title_menu = QtWidgets.QMenu('Available Titles')
        self.title_menu.aboutToShow.connect(self._build_title_menu)
        self.ui.title_field.menu.addMenu(self.title_menu)

        self.ui.class_field.add_action(
            'Set to "*" Any Class', partial(self.ui.class_field.setText, '*')
        )
        self.ui.class_field.add_action(
            'Insert ".*" Wildcard', partial(self.ui.class_field.insert, '.*')
        )
        self.class_menu = QtWidgets.QMenu('Available Class Names')
        self.class_menu.aboutToShow.connect(self._built_classes_menu)
        self.ui.class_field.menu.addMenu(self.class_menu)

    def _built_classes_menu(self):
        self._build_availables_menu(self.class_menu, 0, 'classes', self.ui.class_field)

    def _build_title_menu(self):
        self._build_availables_menu(self.title_menu, 1, 'titles', self.ui.title_field)

    def _build_availables_menu(self, menu, data_index, name, widget):
        menu.clear()
        process_name = self.data[self.selected_name]['process']
        proc_win_data = self._fetch_window_data(process_name)
        if proc_win_data:
            for title in set([win[data_index] for win in proc_win_data if win[data_index]]):
                menu.addAction(title, partial(widget.setText, title))
        else:
            action = menu.addAction(NO_AVAILABLE_TXT % (name, process_name))
            action.setEnabled(False)

    def _fetch_window_data(self, process_name):
        this_path = self.draw_ctrl.mod.path
        cmd = os.path.join(this_path, 'sessionrestore_get_windows.ahk')
        window_data_str = a2ahk.call_cmd(cmd, process_name, cwd=this_path)
        try:
            window_data = json.loads(window_data_str)
            return window_data
        except Exception as error:
            log.error('Could not get JSON data from window data string:\n  %s', window_data_str)
            log.error(error)
        return []

    def _fetch_window_process_list(self):
        scope_nfo = a2ahk.call_lib_cmd('get_scope_nfo')
        scope_nfo = scope_nfo.split('\n')
        if not scope_nfo:
            log.error('Error getting scope_nfo!! scope_nfo: %s', scope_nfo)
            return

        processes = {}
        num_items = len(scope_nfo)
        num_items -= num_items % 3
        for i in range(0, num_items, 3):
            proc_name = scope_nfo[i + 2]
            if not proc_name:
                continue
            _proc_name = proc_name.lower()
            if _proc_name in processes:
                continue
            processes[_proc_name] = proc_name

        for proc_name in sorted(processes.values(), key=lambda x: x.lower()):
            self._process_menu.addAction(proc_name, partial(self.add_process, proc_name))

    def add_process(self, name):
        """Append a process name to the current list."""
        import a2util

        # for now we're just filling with the data of 1st found window
        win_data = self._fetch_window_data(name)[0]

        new_name = a2util.get_next_free_number(name, self.data.keys(), ' ')
        self.data[new_name] = {
            'process': name,
            'class': win_data[0],
            'title': win_data[1],
            'xy': (win_data[2], win_data[3]),
            'wh': (win_data[4], win_data[5]),
        }

        self.add_named_item(new_name)
        self.data_changed.emit()

    def add_item(self):
        self._process_menu.clear()
        self._fetch_window_process_list()
        self._process_menu.popup(QtGui.QCursor.pos())


class Draw(DrawCtrl):
    """
    The frontend widget visible to the user with options
    to change the default behavior of the element.
    """

    def __init__(self, *args):
        super(Draw, self).__init__(*args)
        self.main_layout = QtWidgets.QVBoxLayout(self)
        self.main_layout.setContentsMargins(0, 0, 0, 0)

        self.size_combobox = QtWidgets.QComboBox()
        size_label = QtWidgets.QLabel('Virtual Desktop Size:')
        size_layout = QtWidgets.QHBoxLayout()
        size_layout.addWidget(size_label)
        size_layout.addWidget(self.size_combobox)
        size_add_button = QtWidgets.QPushButton('Add Size')
        size_add_button.setEnabled(False)
        size_layout.addWidget(size_add_button)
        self.main_layout.addLayout(size_layout)

        self.desktop_icons_check = QtWidgets.QCheckBox('Restore Desktop Icons')
        self.desktop_icons_check.clicked[bool].connect(self.desktop_icons_checked)
        self.main_layout.addWidget(self.desktop_icons_check)

        self.editor = SessionRestoreWindowLister({}, self)
        self.editor.data_changed.connect(self.delayed_check)
        self.main_layout.addWidget(self.editor)

        self.is_expandable_widget = True

        self._validate_setups()

        self.size_combobox.currentTextChanged.connect(self._size_selected)
        self.size_combobox.addItems(self._size_keys)
        self._size_selected()

    def desktop_icons_checked(self, value=None):
        if self._drawing:
            return

        change = False
        if value and 'icons' not in self.user_cfg.get(self._size_key, {}):
            self.user_cfg.setdefault(self._size_key, {})['icons'] = True
            change = True
        elif not value and 'icons' in self.user_cfg.get(self._size_key, {}):
            del self.user_cfg[self._size_key]['icons']
            change = True

        if change:
            self.delayed_check()

    def _validate_setups(self):
        if not self.user_cfg:
            return

        first_key_name = list(self.user_cfg.keys())[0].lower()
        if '.exe' in first_key_name:
            print('updating the dictionary ...')
            this_path = self.mod.path
            cmd = os.path.join(this_path, 'sessionrestore_get_virtual_screen_size.ahk')
            virtual_screen_size = a2ahk.call_cmd(cmd, cwd=this_path)
            print('  virtual_screen_size: %s' % virtual_screen_size)

            if virtual_screen_size in self.user_cfg:
                del self.user_cfg[virtual_screen_size]

            self.user_cfg = {virtual_screen_size: {'setups': self.user_cfg.copy()}}
            self.set_user_value(self.user_cfg)

            # import pprint
            # print('  current element cfg:')
            # pprint.pprint(self.user_cfg)

        change = False
        for virtual_screen_size in list(self.user_cfg.keys()):
            setups = self.user_cfg[virtual_screen_size]
            if 'setups' not in setups:
                del self.user_cfg[virtual_screen_size]
                self.user_cfg = {virtual_screen_size: {'setups': setups.copy()}}
                change = True

        if change:
            self.set_user_value(self.user_cfg)

    def check(self, *args):
        super(Draw, self).check()
        self.user_cfg.setdefault(self._size_key, {}).update({'setups': self.editor.data})
        # self.user_cfg[self._size_key] = self.editor.data

        self.set_user_value(self.user_cfg)
        self.change()

    @property
    def _size_keys(self):
        return sorted(self.user_cfg.keys())

    @property
    def _size_key(self):
        text = self.size_combobox.currentText()
        return text

    def _size_selected(self, value=None):
        self._drawing = True
        if value is None:
            if not self._size_keys:
                return
            value = self._size_keys[0]

        self.editor.data = self.user_cfg.get(value, {}).get('setups', {})
        self.desktop_icons_check.setChecked(self.user_cfg.get(value, {}).get('icons', False))
        self.editor.fill_item_list()
        self._drawing = False


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
    window_dict = {}
    for size_key, this_dict in user_cfg.items():
        window_list = []
        this_size_dict = this_dict.get('setups', {})
        for this_win_dict in this_size_dict.values():
            xy, wh = this_win_dict.get('xy', (0, 0)), this_win_dict.get('wh', (0, 0))
            window_list.append(
                [
                    this_win_dict['process'],
                    this_win_dict.get('class', ''),
                    this_win_dict.get('title', DEFAULT_TITLE),
                    xy[0],
                    xy[1],
                    wh[0],
                    wh[1],
                    this_win_dict.get('ignore', False),
                ]
            )
        window_dict[size_key] = window_list
        if this_dict.get('icons', False):
            icons_flag = '%s_icons' % size_key
            window_dict[icons_flag] = True
    db_dict['variables']['SessionRestore_List'] = window_dict
