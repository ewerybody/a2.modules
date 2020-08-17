"""
Script to turn the text list from https://cloud.google.com/translate/docs/languages
into a nice, little json.
"""
import os
import a2util

THIS_DIR = os.path.abspath(os.path.dirname(__file__))
FILE_NAME = 'languages'
SOURCE_FILE = os.path.join(THIS_DIR, FILE_NAME + '.txt')
DATA_FILE = os.path.join(THIS_DIR, FILE_NAME + '.json')
_DATA = {}
SEPARATOR = ' > '
AUTO_KEY = 'auto'
AUTO_LANGUAGE = 'Detect Language (auto)'
DEFAULT = 'en'
DEFAULT_TRANSLATION = AUTO_KEY + SEPARATOR + DEFAULT


def get():
    """Read data file, pass dict with language name: key."""
    if not _DATA:
        _DATA.update(a2util.json_read(DATA_FILE))
    return _DATA


def source_to_json():
    """Here you have a docstring."""
    if not os.path.isfile(SOURCE_FILE):
        raise FileNotFoundError('No Source File! (%s)' % SOURCE_FILE)

    data = {}
    with open(SOURCE_FILE) as file_obj:
        for line in file_obj:
            line = line.strip()
            if not line:
                continue

            try:
                name, key = line.rsplit(None, 1)
                data[name] = key
            except ValueError:
                continue

    a2util.json_write(DATA_FILE, data)


def key_to_name(key):
    """Find the language full name from a short key."""
    if key == AUTO_KEY:
        return AUTO_LANGUAGE
    langs = get()
    for name, this_key in langs.items():
        if this_key == key:
            return name
    return key_to_name(DEFAULT)


if __name__ == "__main__":
    source_to_json()
