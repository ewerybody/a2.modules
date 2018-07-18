# -*- coding: utf-8 -*-
import os
import a2util
import a2ctrl
from PySide2 import QtWidgets
from a2element import DrawCtrl, EditCtrl
from a2widget.a2item_editor import A2ItemEditor
from a2widget import A2TextField


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


class HotStringsEditor(A2ItemEditor):

    def __init__(self, user_cfg, parent):

        self.data = user_cfg
        self.draw_labels = False

        super(HotStringsEditor, self).__init__(parent)

        self.ui.text = A2TextField(self)
        self.add_data_widget('text', self.ui.text, self.ui.text.setText, self.ui.text.editing_finished,
                             default_value='')

        for name, label in hs_checkboxes:
            checkbox = QtWidgets.QCheckBox(self)
            checkbox.setText(label)
            self.add_data_widget(name, checkbox, checkbox.setChecked,
                                 default_value=False)

        self.ui.case = QtWidgets.QComboBox(self)
        self.ui.case.addItems(['Ignore Case', 'Case Sensitive', 'Don\'t Conform To Typed Case'])
        self.add_data_widget('case', self.ui.case, self.ui.case.setCurrentIndex,
                             default_value=0)

        self.ui.scope = QtWidgets.QComboBox(self)
        self.ui.scope.addItems(['Scope: Global', 'Scope: Only In:', 'Scope: Not In:'])
        self.ui.scope.currentIndexChanged.connect(self.toggle_scope_field)
        self.add_data_widget('scope', self.ui.scope, self.ui.scope.setCurrentIndex,
                             default_value=0)

        self.ui.scope_field = QtWidgets.QLineEdit(self)
        self.ui.scope_field.setVisible(False)
        self.add_data_widget('scope_field', self.ui.scope_field, self.ui.scope_field.setText,
                             default_value='')

        spacer = QtWidgets.QSpacerItem(0, 0, QtWidgets.QSizePolicy.Minimum, QtWidgets.QSizePolicy.Expanding)
        self.ui.config_layout.addItem(spacer)

    def toggle_scope_field(self, index=None):
        """only show the scope field if not global"""
        self.ui.scope_field.setVisible(index != 0)


class Draw(DrawCtrl):
    """
    The frontend widget visible to the user with options
    to change the default behavior of the element.
    """
    def __init__(self, *args):
        # cfg.setdefault('name', 'hotstrings')
        super(Draw, self).__init__(*args)
        self._hs_lines_b4 = None
        self._setup_ui()
        self.is_expandable_widget = True

        self.hotstrings_file = os.path.join(self.paths.mod_data, HOTSTRINGS_FILENAME)
        self._check_hs_include_file()

    def _setup_ui(self):
        self.main_layout = QtWidgets.QVBoxLayout(self)
        self.main_layout.setContentsMargins(0, 0, 0, 0)
        self.editor = HotStringsEditor(self.user_cfg, self)
        self.editor.data_changed.connect(self.delayed_check)
        self.main_layout.addWidget(self.editor)

    def check(self, *args):
        print('check')
        self.set_user_value(self.editor.data)

        hs_lines = []
        # write hotstrings.ahk
        for hs, data in self.editor.data.items():
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
        a2util.write_utf8(self.hotstrings_file, '\n'.join(hs_lines))

        self.change()

    def _check_hs_include_file(self):
        # make sure at least an empty file is there to be included
        os.makedirs(self.paths.mod_data, exist_ok=True)
        if not os.path.isfile(self.hotstrings_file):
            with open(self.hotstrings_file, 'w') as fobj:
                fobj.write('')


class Edit(EditCtrl):
    """
    The background widget that sets up how the user can edit the element,
    visible when editing the module.
    """
    def __init__(self, cfg, main, parent_cfg):
        super(Edit, self).__init__(cfg, main, parent_cfg)
        self.mainLayout.addWidget(QtWidgets.QLabel(
            'Nothing to setup on the HotStrings element. This one is all for the user.'))

    @staticmethod
    def element_name():
        """The elements display name shown in UI"""
        return 'Hotstrings'

    @staticmethod
    def element_icon():
        return a2ctrl.Icons.inst().check


def get_settings(_module_key, _cfg, db_dict, _user_cfg):
    """
    So far this only adds the hotstrings.ahk to includes.
    """
    db_dict.setdefault('data_includes', []).append(HOTSTRINGS_FILENAME)
