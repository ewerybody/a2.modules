import a2ctrl
from a2qt import QtWidgets
from a2element import DrawCtrl, EditCtrl
from a2widget import a2item_editor, a2text_field


class Draw(DrawCtrl):
    def __init__(self, *args):
        super(Draw, self).__init__(*args)
        self.main_layout = QtWidgets.QVBoxLayout(self)
        self.main_layout.setContentsMargins(0, 0, 0, 0)

        self.editor = a2item_editor.A2ItemEditor(self)
        self.editor.ignore_default_values = False
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

        ask_check = QtWidgets.QCheckBox('Ask for file name', self)
        self.editor.add_data_label_widget(
            'ask', ask_check, ask_check.setChecked, ask_check.clicked, True, ''
        )

    def check(self):
        self.user_cfg.update(self.editor.data)
        self.set_user_value(self.user_cfg)
        self.change()


class Edit(EditCtrl):
    def __init__(self, cfg, main, parent_cfg):
        super(Edit, self).__init__(cfg, main, parent_cfg)

    @staticmethod
    def element_name():
        """The elements display name shown in UI"""
        return 'File_List'

    @staticmethod
    def element_icon():
        return a2ctrl.Icons.inst().check


def get_settings(module_key, cfg, db_dict, user_cfg):
    if user_cfg:
        db_dict['variables']['explorer_create_file_data'] = user_cfg
