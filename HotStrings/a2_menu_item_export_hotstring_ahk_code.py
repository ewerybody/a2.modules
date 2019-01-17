# a2 menu item script "export_hotstring_ahk_code"
from PySide2 import QtWidgets


def main(a2, mod):
    """
    :param a2: Main A2 object instance.
    :param mod: Current a2 module instance.
    """
    title = 'Export Hotstrings Code ...'
    print(title)

    file_path, _filter = QtWidgets.QFileDialog.getSaveFileName(
        None, title, a2.paths.a2, '*.ahk')

    if file_path:
        import a2util
        import hotstrings_io
        name = 'hotstrings'
        hs_current = mod.get_user_cfg()[name]
        code = hotstrings_io.dict_to_ahkcode(hs_current)
        a2util.write_utf8(file_path, code)
