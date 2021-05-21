import os
import a2util
from a2qt import QtWidgets
import hotstrings_io


def main(a2, mod):
    """
    :param a2: Main A2 object instance.
    :param mod: Current a2 module instance.
    """
    title = 'Export Hotstrings - All'
    AHK, JSON = '*.ahk', '*.json'
    file_path, file_type = QtWidgets.QFileDialog.getSaveFileName(
        a2.win, title, a2.paths.a2, '\n'.join((AHK, JSON))
    )
    if not file_path:
        return

    file_type = '*' + os.path.splitext(file_path)[1].lower()
    Args = hotstrings_io.Args
    groups = mod.get_user_cfg().get(Args.hotstrings, {}).get(Args.groups, {})
    if file_type == AHK:
        hs_scopes = hotstrings_io.groups_to_scopes(groups)
        code = hotstrings_io.dict_to_ahkcode(hs_scopes)
        a2util.write_utf8(file_path, code)
    elif file_type == JSON:
        a2util.json_write(file_path, groups)
    else:
        raise NotImplementedError('Unknown file type "%s"!' % file_type)
