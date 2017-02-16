# -*- coding: utf-8 -*-
"""
Some element description ...

@created: 2016 9 24
@author: eRiC
"""
import os
import codecs
import a2ctrl
from PySide import QtGui, QtCore
from a2element import DrawCtrl, EditCtrl
from a2widget.a2item_editor import A2ItemEditor
from a2widget import a2TextField
from collections import OrderedDict

HOTSTRINGS_FILENAME = 'hotstrings.ahk'
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
        self.fill_items(sorted(self.user_cfg.keys(), key=str.lower))

        self._current_cfg = {}
        self._config_widgets = OrderedDict()

        self.ui.text = a2TextField(self)
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
        self.ui.scope_field.setVisible(False)
        self.ui.scope_field.setObjectName('scope_field')
        self._config_widgets['scope_field'] = self.ui.scope_field

        for widget in self._config_widgets.values():
            self.ui.config_layout.addWidget(widget)

        # we connect the text field with the editing finished signal and
        # all the other ones standard like
        standard_controls = list(self._config_widgets.values())[1:]
        a2ctrl.connect.control_list(standard_controls, self._current_cfg, self._cfg_changed)
        a2ctrl.connect.control(self.ui.text, 'text', self._current_cfg, self._cfg_changed,
                               trigger_signal=self.ui.text.editing_finished)
        self._cfg_changed.connect(self.update_config)

        spacer = QtGui.QSpacerItem(0, 0, QtGui.QSizePolicy.Minimum, QtGui.QSizePolicy.Expanding)
        self.ui.config_layout.addItem(spacer)

        self.selected_name_changed.connect(self.draw_data)
        self.item_changed.connect(self.item_rename)
        self.item_deleted.connect(self.item_remove)
        self._drawing = False

    def item_rename(self, item_tuple):
        old_name, new_name, _item = item_tuple
        data = self.user_cfg.pop(old_name) if old_name else {}
        self.user_cfg[new_name] = data
        self.draw_data(new_name)
        self.hotstring_changed.emit()

    def item_remove(self, name):
        self.user_cfg.pop(name)
        self.hotstring_changed.emit()

    def update_config(self):
        """
        Shall always update the config but not trigger change if there was no text set
        and text was not deleted.
        """
        if self._drawing:
            return

        diff_dict = {}
        for key, value in self._current_cfg.items():
            if value != default_dict[key]:
                diff_dict[key] = value

        self.user_cfg[self.selected_name] = diff_dict
        self.hotstring_changed.emit()

    def draw_data(self, item_name):
        self._drawing = True
        cfg = self.user_cfg.get(item_name, default_dict)

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
        self._hs_lines_b4 = None
        self._setupUi()
        self.is_expandable_widget = True

    def _setupUi(self):
        self.layout = QtGui.QVBoxLayout(self)
        self.editor = HotStringsEditor(self.user_cfg or {}, self)
        self.editor.hotstring_changed.connect(self.delayed_check)
        self.layout.addWidget(self.editor)
        self.setLayout(self.layout)

    def check(self, *args):
        DrawCtrl.check(self, *args)
        self.set_user_value(self.editor.user_cfg)

        hs_lines = []
        # write hotstrings.ahk
        for hs, data in self.editor.user_cfg.items():
            text = data.get('text')
            if not text or not hs:
                continue
            text = text.replace('\n', '`n')
            # TODO: if not raw:
            text = text.replace('!', '{!}')
            hs_option = ':'
            if data.get('instant'):
                hs_option += '*'
            case = data.get('case')
            if case == 1:
                hs_option += 'C'
            elif case == 2:
                hs_option += 'C1'
            hs_option += ':'
            hs_lines.append('%s%s::%s' % (hs_option, hs, text))

        hs_lines = ['#IfWinActive,'] + hs_lines
        if hs_lines == self._hs_lines_b4:
            return
        self._hs_lines_b4 = hs_lines
        hs_ahk_path = os.path.join(self.a2.paths.settings, HOTSTRINGS_FILENAME)
        with codecs.open(hs_ahk_path, 'wb', encoding='utf-8-sig') as fobj:
            fobj.write('\n'.join(hs_lines))

        self.change()


class Edit(EditCtrl):
    """
    The background widget that sets up how the user can edit the element,
    visible when editing the module.
    """
    def __init__(self, cfg, main, parentCfg):
        super(Edit, self).__init__(cfg, main, parentCfg)
        self.mainLayout.addWidget(QtGui.QLabel('Nothing to setup on the HotStrings element.'
                                               'This one is all for the user.'))

    @staticmethod
    def element_name():
        """The elements display name shown in UI"""
        return 'Hotstrings'

    @staticmethod
    def element_icon():
        return a2ctrl.Icons.inst().check


def get_settings(module_key, cfg, db_dict, user_cfg):
    """
    So far this only adds the hotstrings.ahk to includes.
    """
    db_dict.setdefault('settings_includes', []).append(HOTSTRINGS_FILENAME)
