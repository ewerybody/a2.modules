from a2qt import QtWidgets

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

        if self._fix_user_data():
            self.set_user_value(self.user_cfg)
            self.change()

        self.editor = DetailsLister(self.user_cfg, self)
        self.editor.data_changed.connect(self.delayed_check)
        self.main_layout.addWidget(self.editor)
        self.is_expandable_widget = True

    def check(self):
        self.user_cfg = self.editor.data
        self.set_user_value(self.user_cfg)
        self.change()

    def _fix_user_data(self):
        """Move strings to the `data` dict if any."""
        changed = False
        for values in self.user_cfg.values():
            for item in list(values):
                if isinstance(values[item], str):
                    values.setdefault('data', {})[item] = values[item]
                    del values[item]
                    changed = True
        return changed


class DetailsLister(A2ItemEditor):
    def __init__(self, cfg, parent):
        self.draw_ctrl = parent
        self.data = cfg or {}
        super(DetailsLister, self).__init__(parent=parent)

        self.key_value_table = KeyValueTable(self)
        self.key_value_table.changed.connect(self._update_data)
        self.enlist_widget('data', self.key_value_table, self.key_value_table.set_data, {})
        self.add_row(self.key_value_table)

        single_check = QtWidgets.QCheckBox(self)
        single_check.setText('Finish after first selected item')
        self.add_data_widget(
            'single_item', single_check, single_check.setChecked, default_value=False
        )

    def _update_data(self):
        if self.selected_name:
            have_data = self.data[self.selected_name]['data']
            table_data = self.key_value_table.get_data()
            if have_data != table_data:
                self.data[self.selected_name]['data'] = table_data
                self.data_changed.emit()


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
        return a2ctrl.Icons.check


def get_settings(module_key, cfg, db_dict, user_cfg):
    if user_cfg:
        db_dict['variables']['details_popup_data'] = user_cfg
