# a2 menu item script "export_hotstring_json"
from PySide2 import QtWidgets


def main(a2, mod):
    """
    :param a2: Main A2 object instance.
    :param mod: Current a2 module instance.
    """
    title = 'Export Hotstrings JSON ...'
    print(title)

    file_path, _filter = QtWidgets.QFileDialog.getSaveFileName(
        None, title, a2.paths.a2, '*.json')

    if file_path:
        import a2util
        name = 'hotstrings'
        hs_current = mod.get_user_cfg()[name]
        a2util.json_write(file_path, hs_current)
