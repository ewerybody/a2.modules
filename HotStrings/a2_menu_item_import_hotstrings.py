# a2 menu item script "import_hotstring"

def main(main, mod):
    print('Import Hotstrings ... %s' % __name__)

    from PySide2 import QtWidgets

    file_path, _ = QtWidgets.QFileDialog.getOpenFileName(
        None, 'Import Hotstrings Data', mod.path, '(*.ahk *.json)')

    if file_path:
        import os
        import a2util
        cwd = os.getcwd()
        print(cwd)
