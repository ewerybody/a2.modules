# a2 menu item script "import_hotstrings"
from a2qt import QtWidgets


def main(a2, mod):
    print('Import Hotstrings ... %s' % __name__)

    file_path, _ = QtWidgets.QFileDialog.getOpenFileName(
        None, 'Import Hotstrings Data', a2.paths.a2, '(*.ahk *.json)'
    )
    if not file_path:
        return

    import os
    import a2util
    import pprint
    import hotstrings_io
    from hotstrings_io import Args

    base, ext = os.path.splitext(os.path.basename(file_path))
    ext = ext.lower()
    if ext == '.ahk':
        hs_input = hotstrings_io.file_to_dict(file_path)
    elif ext == '.json':
        hs_input = a2util.json_read(file_path)

    hotstrings_io.scopes_to_groups(hs_input)

    current_cfg = mod.get_user_cfg().get(Args.hotstrings, {})
    current_groups = current_cfg.get(Args.groups, {})
    current_names = list(current_groups)
    for name, group in hs_input.get(Args.groups, {}).items():
        name = f'Imported - {base} {name}'
        name = a2util.get_next_free_number(name, current_names)
        group[Args.enabled] = False
        current_groups[name] = group
        current_names.append(name)

    mod.set_user_cfg({'name': hotstrings_io.Args.hotstrings}, current_cfg)
    a2.win.load_runtime_and_ui()
    a2.win.check_element(Args.hotstrings)
