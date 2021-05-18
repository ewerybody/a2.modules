# a2 menu item script "export_hotstring_ahk_code"
from a2qt import QtWidgets


def main(a2, mod):
    """
    :param a2: Main A2 object instance.
    :param mod: Current a2 module instance.
    """
    title = 'Export Hotstrings Code ...'
    print(title)

    file_path, _filter = QtWidgets.QFileDialog.getSaveFileName(None, title, a2.paths.a2, '*.ahk')
    if not file_path:
        return

    import a2util
    import hotstrings_io

    Args = hotstrings_io.Args
    hs_current = hotstrings_io.groups_to_scopes(
        mod.get_user_cfg()[Args.hotstrings][Args.groups]
    )
    code = hotstrings_io.dict_to_ahkcode(hs_current)
    a2util.write_utf8(file_path, code)
