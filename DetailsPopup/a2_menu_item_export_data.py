import a2util
from PySide2 import QtWidgets


def main(a2, mod):
    element_name = 'details_lister'
    current_data = mod.get_user_cfg().setdefault(element_name, {})
    if not current_data:
        Msgbox = QtWidgets.QMessageBox
        cfg = Msgbox.Abort | Msgbox.Retry | Msgbox.Ignore
        Msgbox.critical(a2.win, 'ERROR', 'There is nothing to export!', *cfg)
        return

    file_path, _filter = QtWidgets.QFileDialog.getSaveFileName(
        a2.win, 'Export Hotstrings Data', a2.paths.a2, '*.json'
    )

    if not file_path:
        return

    a2util.json_write(file_path, current_data)
