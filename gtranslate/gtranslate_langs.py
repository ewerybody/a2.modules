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


def get():
    """Read data file, pass dict with language name: key."""
    return a2util.json_read(DATA_FILE)


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


if __name__ == "__main__":
    source_to_json()
