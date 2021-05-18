# a2 menu item script "export_hotstring_json"
from a2qt import QtWidgets


def main(a2, mod):
    """
    :param a2: Main A2 object instance.
    :param mod: Current a2 module instance.
    """
    title = 'Export Hotstrings JSON ...'
    print(title)

    file_path, _filter = QtWidgets.QFileDialog.getSaveFileName(None, title, a2.paths.a2, '*.json')

    if not file_path:
        return

    import a2util
    from hotstrings_io import Args

    groups = mod.get_user_cfg().get(Args.hotstrings, {}).get(Args.groups, {})
    a2util.json_write(file_path, groups)
