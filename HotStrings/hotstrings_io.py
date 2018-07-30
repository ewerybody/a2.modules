# -*- coding: utf-8 -*-
import codecs
import enum


# for the on/off options
class Options(enum.Enum):
    instant = '*'
    ignore = 'O'
    inside = '?'
    append = 'B0'

# for the dropdown menus
OPTION_LISTS = {
    'case': ['C', 'C1'],
    'send': ['SI', 'SP', 'SE']}


def dict_to_hotstrings(hotstrings_data):
    lines = []
    for hotstring, data in hotstrings_data.items():
        text = data.get('text')
        if not text or not hotstring:
            continue

        options = ':'
        for op in Options:
            if data.get(op.name, False):
                options += op.value

        for name, option_list in OPTION_LISTS.items():
            value = data.get(name)
            if value:
                options += option_list[value - 1]

        text = text.replace('\n', '`n')
        mode = data.get('mode')
        if mode is None:
            for char in '!+#^':
                text = text.replace(char, '{%s}' % char)
        elif mode == 1:
            text = text.strip()
            if '`n' in text:
                indent = '\n  '
                text = indent + indent.join(text.split('`n'))
                text += '\nReturn'
            else:
                options += 'X'
        elif mode == 2:
            # This is actually the default mode! Nothing to do!
            pass
        elif mode == 3:
            options += 'R'
        elif mode == 4:
            options += 't'

        lines.append(f'{options}:{hotstring}::{text}')

    lines = ['#IfWinActive,'] + lines
    return '\n'.join(lines)


def hotstrings_file_to_dict(path):
    hotstrings = {}
    current_scope = '#IfWinActive,'
    with codecs.open(path, encoding='utf-8-sig') as fobj:
        for line in fobj:
            line = line.strip()
            if line.lower().startswith('#ifwin'):
                current_scope = line
            if line.startswith(':'):
                hotstrings[current_scope] = line
                print('line:', line)


if __name__ == '__main__':
    # p = 'hotstrings.ahk'
    # hotstrings_file_to_dict(p)
    pass
