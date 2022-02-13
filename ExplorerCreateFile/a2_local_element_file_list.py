import os

import a2util
import a2ctrl
from a2ctrl import Icons
from a2qt import QtWidgets
from a2element import DrawCtrl, EditCtrl
from a2widget import a2item_editor, a2text_field, a2combo

THIS_DIR = os.path.abspath(os.path.dirname(__file__))
ENCODINGS = a2util.json_read(os.path.join(THIS_DIR, 'encodings.json'))


class Draw(DrawCtrl):
    def __init__(self, *args):
        super(Draw, self).__init__(*args)
        self.main_layout = QtWidgets.QVBoxLayout(self)
        self.main_layout.setContentsMargins(0, 0, 0, 0)

        self.editor = a2item_editor.A2ItemEditor(self)
        self.editor.ui.item_editor_layout.setStretch(0, 1)
        self.editor.ui.item_editor_layout.setStretch(1, 4)
        self.editor.ignore_default_values = False
        if not self.user_cfg:
            self.editor.set_data(a2util.json_read(os.path.join(THIS_DIR, 'defaults.json')))
            self.check()

        self.editor.set_data(self.user_cfg)
        self.editor.data_changed.connect(self.delayed_check)
        self.main_layout.addWidget(self.editor)
        self.is_expandable_widget = True

        ext_field = QtWidgets.QLineEdit(self)
        self.editor.add_data_label_widget(
            'ext', ext_field, ext_field.setText, ext_field.textChanged, '.txt', 'File Extension'
        )

        name = QtWidgets.QLineEdit(self)
        self.editor.add_data_label_widget(
            'file_name', name, name.setText, name.textChanged, '', 'Default File Name'
        )

        # We do the icons now from the system. Maaaaybe we could have an override
        # but this way its already much easier most of the time.
        # icon_field = QtWidgets.QLineEdit(self)
        # self.editor.add_data_label_widget(
        #     'icon', icon_field, icon_field.setText, icon_field.textChanged, ''
        # )

        content = a2text_field.A2CodeField(self)
        self.editor.add_data_label_widget(
            'content', content, content.setText, content.editing_finished, '', 'Default Content'
        )

        encoding_combo = a2combo.A2Combo(self)
        encoding_combo.setEditable(True)
        encoding_combo.addItems(ENCODINGS)
        encoding_help = QtWidgets.QToolButton(autoRaise=True, icon=Icons.help)
        encoding_help.clicked.connect(_encoding_docs)
        combo_lyt = QtWidgets.QHBoxLayout()
        combo_lyt.addWidget(encoding_combo)
        combo_lyt.addWidget(encoding_help)
        combo_lyt.setStretch(0, 1)

        self.editor.add_row('Encoding', combo_lyt)
        self.editor.connect_data_widget(
            'encoding',
            encoding_combo,
            encoding_combo.setCurrentText,
            encoding_combo.currentTextChanged,
            list(ENCODINGS)[0],
        )

        ask_check = QtWidgets.QCheckBox('Ask for file name', self)
        self.editor.add_data_label_widget(
            'ask', ask_check, ask_check.setChecked, ask_check.clicked, True, ''
        )

    def check(self):
        self.user_cfg.update(self.editor.data)
        self.set_user_value(self.user_cfg)
        self.change()


def _encoding_docs():
    import a2util

    a2util.surf_to('https://autohotkey.com/docs/commands/FileEncoding.htm')


class Edit(EditCtrl):
    def __init__(self, cfg, main, parent_cfg):
        super(Edit, self).__init__(cfg, main, parent_cfg)

    @staticmethod
    def element_name():
        """The elements display name shown in UI"""
        return 'File_List'

    @staticmethod
    def element_icon():
        return a2ctrl.Icons.check


def get_settings(module_key, cfg, db_dict, user_cfg):
    if user_cfg:
        for typ, data in user_cfg.items():
            # replace display with AUtohotkey encoding names
            if data.get('encoding') in ENCODINGS:
                data['encoding'] = ENCODINGS[data['encoding']]
        db_dict['variables']['explorer_create_file_data'] = user_cfg
