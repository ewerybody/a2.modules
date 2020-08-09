"""
Script to turn the text list from https://cloud.google.com/translate/docs/languages
into a nice, little json.
"""
import os
import a2util

THIS_DIR = os.path.abspath(os.path.dirname(__file__))
NAME = 'languages'


def main():
    """Here you have a docstring."""
    source = os.path.join(THIS_DIR, NAME + '.txt')
    if not os.path.isfile(source):
        raise FileNotFoundError('No Source File! (%s)' % source)

    data = {}
    with open(os.path.join(THIS_DIR, NAME + '.txt')) as file_obj:
        for line in file_obj:
            line = line.strip()
            if not line:
                continue

            try:
                name, key = line.rsplit(None, 1)
                data[name] = key
            except ValueError:
                continue

    target = os.path.join(THIS_DIR, NAME + '.json')
    a2util.json_write(target, data)


if __name__ == "__main__":
    main()
