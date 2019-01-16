# a2 menu item script "import_hotstring"

def main(a2, mod):
    """
    :param a2: Main A2 object instance.
    :param mod: Current a2 module instance.
    """
    print('Import Hotstrings ... %s' % __name__)

    from PySide2 import QtWidgets

    file_path, _ = QtWidgets.QFileDialog.getOpenFileName(
        None, 'Import Hotstrings Data', mod.path, '(*.ahk *.json)')

    if not file_path:
        return

    import os
    import a2util
    import pprint
    import hotstrings_io
    name = 'hotstrings'
    base, ext = os.path.splitext(file_path)
    ext = ext.lower()
    if ext == '.ahk':
        hs_input = hotstrings_io.file_to_dict(file_path)
    elif ext == '.json':
        hs_input = a2util.json_read(file_path)

    hs_current = mod.get_user_cfg()[name]
    hs_collisions = {}
    for mode, scope, hstring, hs_cfg in hotstrings_io.iterate(hs_input):
        if mode == '':
            if hstring not in hs_current.get('', {}):
                target = hs_current
            else:
                target = hs_collisions
            target.setdefault('', {})[hstring] = hs_cfg
        else:
            if hstring not in hs_current.get(mode, {}).get(scope, {}):
                target = hs_current
            else:
                target = hs_collisions
            target.setdefault(mode, {}).setdefault(scope, {})[hstring] = hs_cfg

    mod.set_user_cfg({'name': name}, hs_current)
    a2.win.load_runtime_and_ui()
    a2.win.check_element(name)

    if hs_collisions:
        print('There were collisions:\n%s' % pprint.pformat(hs_collisions))
        backup_path = base + '_collisions.json'
        a2util.json_write(backup_path, hs_collisions)
        a2util.explore(backup_path)
