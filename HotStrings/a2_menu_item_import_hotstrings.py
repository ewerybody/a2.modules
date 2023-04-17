# a2 menu item script "import_hotstrings"
import a2core
import a2mod
from a2qt import QtWidgets

log = a2core.get_logger(__name__)


def main(a2: a2core.A2Obj, mod: a2mod.Mod):
    file_path, _ = QtWidgets.QFileDialog.getOpenFileName(
        None, 'Import Hotstrings Data', a2.paths.a2, '(*.ahk *.json)'
    )
    if not file_path:
        return

    log.info('Importing Hotstrings from ...\n  %s', file_path)

    import os
    import a2util
    import hotstrings_io
    from hotstrings_io import Args

    base = os.path.basename(file_path)
    ext = os.path.splitext(base)[1].lower()
    if ext == '.ahk':
        hs_input = hotstrings_io.file_to_dict(file_path)
    elif ext == '.json':
        hs_input = a2util.json_read(file_path)
    else:
        raise NotImplementedError(f'Unknown file type "{ext}"!')

    hotstrings_io.scopes_to_groups(hs_input)

    current_cfg = mod.get_user_cfg().get(Args.hotstrings, {})
    current_groups = current_cfg.get(Args.groups, {})
    current_names = list(current_groups)

    new_group_name, num_hotstrings, num_groups = None, 0, 0
    for name, group in hs_input.get(Args.groups, {}).items():
        if not Args.hotstrings in group:
            continue
        if not group[Args.hotstrings]:
            continue
        name = f'Imported {base} - {name}'
        name = a2util.get_next_free_number(name, current_names)
        group[Args.enabled] = False
        current_groups[name] = group
        current_names.append(name)
        if new_group_name is None:
            new_group_name = name

    if not new_group_name:
        return

    # # the only widget here should be the hotstrings item editor:
    # hotstring_widget = a2.win.module_view.controls[1]
    # hotstring_widget.current_group = current_cfg[Args.groups][new_group_name]
    # hotstring_widget.fill_group_combo()
    # hotstring_widget.select_group(new_group_name)
    current_cfg[Args.last_group] = new_group_name

    mod.set_user_cfg({Args.hotstrings: current_cfg})
    a2.win.load_runtime_and_ui()
    a2.win.check_element(Args.hotstrings)
