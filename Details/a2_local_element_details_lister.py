from PySide2 import QtWidgets

import a2ctrl
from a2element import DrawCtrl, EditCtrl
from a2widget.a2item_editor import A2ItemEditor
from a2widget.key_value_table import KeyValueTable


class Draw(DrawCtrl):
    """
    The frontend widget visible to the user with options
    to change the default behavior of the element.
    """
    def __init__(self, *args):
        super(Draw, self).__init__(*args)
        self.main_layout = QtWidgets.QVBoxLayout(self)
        self.main_layout.setContentsMargins(0, 0, 0, 0)

        self.editor = DetailsLister({}, self)
        self.editor.data_changed.connect(self.delayed_check)
        self.main_layout.addWidget(self.editor)
        self.is_expandable_widget = True

    def check(self):
        self.editor.data
        # self.user_cfg.setdefault(self._size_key, {}).update({'setups': self.editor.data})
        # self.user_cfg[self._size_key] = self.editor.data

        # self.set_user_value(self.user_cfg)
        self.change()


class DetailsLister(A2ItemEditor):
    def __init__(self, cfg, parent):
        super(DetailsLister, self).__init__(parent=parent)
        self.draw_ctrl = parent
        self.data = cfg or {}

        self.key_value_table = KeyValueTable(self)
        self.ui.config_layout.addRow(self.key_value_table)


class Edit(EditCtrl):
    """
    The background widget that sets up how the user can edit the element,
    visible when editing the module.
    """
    def __init__(self, cfg, main, parent_cfg):
        super(Edit, self).__init__(cfg, main, parent_cfg)

    @staticmethod
    def element_name():
        """The elements display name shown in UI"""
        return 'Details_Lister'

    @staticmethod
    def element_icon():
        return a2ctrl.Icons.inst().check


def get_settings(module_key, cfg, db_dict, user_cfg):
    details_popup_data = {}
    for size_key, this_dict in user_cfg.items():
        this_dict
        size_key
    db_dict['variables']['details_popup_data'] = details_popup_data
