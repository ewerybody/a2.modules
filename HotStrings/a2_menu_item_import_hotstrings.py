# a2 menu item script "import_hotstrings"
import a2core
import a2mod
from a2qt import QtWidgets

log = a2core.get_logger(__name__)
SUCCESS_MSG = (
    'Importing {file_name} there were {num_hotstrings} Hotstrings '
    'in {num_groups} groups:\n {groups}\n'
    'The first imported group is seleced now but these are not yet enabled!'
    'Review the import first and then enable a group through the menu.'
)


def main(a2: a2core.A2Obj, mod: a2mod.Mod):
    file_path, _ = QtWidgets.QFileDialog.getOpenFileName(
        a2.win, 'Import Hotstrings Data', a2.paths.a2,
        'Autohotkey (*.ahk);;JSON (*.json);;Guess Type (*.*)'
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
        try:
            hs_input = hotstrings_io.file_to_dict(file_path)
        except Exception as parse_error:
            try:
                hs_input = a2util.json_read(file_path)
            except Exception as json_error:
                raise RuntimeError(
                    'Unable to guess type from file!\n'
                    f'  parse error: {parse_error}'
                    f'  JSON error: {json_error}'
                ) from json_error

    hotstrings_io.scopes_to_groups(hs_input)

    current_cfg = mod.get_user_cfg().get(Args.hotstrings, {})
    current_groups = current_cfg.get(Args.groups, {})
    current_names = list(current_groups)

    new_group_names, num_hotstrings = [], 0
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
        new_group_names.append(name)
        num_hotstrings += len(group.get(Args.hotstrings, ()))

    if not new_group_names:
        QtWidgets.QMessageBox.critical(
            a2.win, 'Nothing imported!', f'There was nothing imported from {base}'
        )
        return

    current_cfg[Args.last_group] = new_group_names[0]

    mod.set_user_cfg({Args.hotstrings: current_cfg})
    a2.win.load_runtime_and_ui()
    a2.win.check_element(Args.hotstrings)

    QtWidgets.QMessageBox.information(
        a2.win, f'{num_hotstrings} Hotstrings Imported!',
        SUCCESS_MSG.format(
            file_name=base, num_hotstrings=num_hotstrings,
            num_groups=len(new_group_names),
            groups='\n '.join(new_group_names)
        )
    )
