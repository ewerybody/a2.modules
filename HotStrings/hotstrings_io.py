# -*- coding: utf-8 -*-
import codecs
import enum
import os


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

DIRECTIVE_INCL = '#IfWinActive'
DIRECTIVE_EXCL = '#IfWinNotActive'
KEY_INCL = 'scope_incl'
KEY_EXCL = 'scope_excl'

def dict_to_hotstrings(hotstrings_data):
    hs_global = []
    scope_incl = {}
    scope_excl = {}

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
        text = text.replace(':', '`:')
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
            options += 'T'

        line = f'{options}:{hotstring}::{text}'
        if KEY_INCL in data:
            scope_incl.setdefault(data.get(KEY_INCL), []).append(line)
        elif KEY_EXCL in data:
            scope_excl.setdefault(data.get(KEY_EXCL), []).append(line)
        else:
            hs_global.append(line)

    code = f'{DIRECTIVE_INCL},\n' + '\n'.join(hs_global)
    for directive, scope_dict in [(DIRECTIVE_INCL, scope_incl), (DIRECTIVE_EXCL, scope_excl)]:
        for scope, scope_lines in scope_dict.items():
            code += f'{directive}, {scope}\n' + '\n'.join(scope_lines)
    return code


def hotstrings_file_to_dict(path):
    hs_dict = {}
    current_scope = ''
    with codecs.open(path, encoding='utf-8-sig') as fobj:
        for line in fobj:
            # cut away comments and strip of whitespace
            line = line.split(';', 1)[0].strip()
            if not line:
                continue

            if line.lower().startswith('#ifwin'):
                current_scope = line
            if line.startswith(':'):
                if not '::' in line or not ':' in line[1:]:
                    print('Not a hotstring? "%s"' % line)
                    continue

                this_hs = {}
                options, rest = line[1:].split(':', 1)

                # disassemble the options
                options = options.lower()
                for op in Options:
                    if op.value.lower() in options:
                        this_hs[op.name] = True
                for name, option_list in OPTION_LISTS.items():
                    for i, op in enumerate(option_list):
                        # we do not break because found "C" can still be "C1"
                        if op in options:
                            this_hs[name] = i + 1
                for op, mode_index in [('x', 1,), ('r', 3), ('t', 4)]:
                    if op in options:
                        this_hs['mode'] = mode_index

                # if shurtcut does not start with :: its easy
                if not rest.startswith('::'):
                    shortcut, text = rest.split('::', 1)
                # otherwise we need to search for the first non-":"
                else:
                    for i, l in enumerate(rest):
                        if l != ':':
                            break
                    pos = rest[i:].find('::')
                    if pos == -1:
                        print('Not a hotstring? "%s"' % line)
                        continue
                    shortcut = rest[:pos + i]
                    text = rest[pos + i + 2:]
                this_hs['text'] = text

                hs_dict.setdefault(current_scope, {})[shortcut] = this_hs
    return hs_dict


if __name__ == '__main__':
    # test back and forth conversion
    this_dir = os.path.dirname(__file__)
    test_file = os.path.join(this_dir, 'test', 'teststrings.ahk')
    from pprint import pprint
    hs_dict = hotstrings_file_to_dict(test_file)
    pprint(hs_dict)

    hs_code = dict_to_hotstrings(hs_dict['#IfWinActive,'])
    print('hs_code:\n%s' % hs_code)
