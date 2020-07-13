# a2 menu item script "a2_menu_item_import_data.py"

def main(a2, mod):
    """
    :param a2: Main A2 object instance.
    :param mod: Current a2 module instance.
    """
    import os
    from PySide2 import QtWidgets

    file_path, _ = QtWidgets.QFileDialog.getOpenFileName(
        None, 'Import Details Data', a2.paths.a2, '(*.json, *.*)')

    if not os.path.isfile(file_path):
        return

    import a2util
    import json
    try:
        data = a2util.json_read(file_path)
    except json.decoder.JSONDecodeError as error:
        raise error

    element_name = 'details_lister'
    elem_cfg = mod.get_user_cfg().setdefault(element_name, {})
    current_data = elem_cfg.get('data', {})
    for cat_name, key_values in data.items():
        if cat_name in current_data:
            cat_name = a2util.get_next_free_number(cat_name, current_data.keys(), '_')
        current_data[cat_name] = key_values

    mod.set_user_cfg({'name': element_name}, elem_cfg)
    a2.win.load_runtime_and_ui()
    a2.win.check_element(element_name)
