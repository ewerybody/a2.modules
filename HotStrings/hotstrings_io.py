"""Autohotkey Hotstrings stuff."""
import enum
import codecs
import a2util


# for the on/off options
class Options(enum.Enum):
    instant = '*'
    ignore = 'O'
    inside = '?'
    append = 'B0'

class Args:
    enabled = 'enabled'
    groups = 'groups'
    hotstrings = 'hotstrings'
    last_group = 'last_group'
    scopes = 'scopes'
    scope_type = 'scope_type'
    default = 'global'

# for the dropdown menus
OPTION_LISTS = {
    'case': ['C', 'C1'],
    'send': ['SI', 'SP', 'SE']}

RAW_MODES = {
    'X': 1,  # code
    'R': 3,  # raw
    'T': 4}  # text

DIRECTIVE_INCL = '#ifwinactive'
DIRECTIVE_EXCL = '#ifwinnotactive'
KEY_INCL = 'scope_incl'
KEY_EXCL = 'scope_excl'
IN_EXCLUDE = (KEY_INCL, KEY_EXCL)


def groups_to_scopes(group_dict: dict) -> dict:
    """Create old-style hotstrings dictionary that can be passed
    to the AHK-Hotstrings-code generator.
    """
    hs_dict = {}
    for group in group_dict.values():
        if not group.get(Args.enabled, True):
            continue

        if scope_type := group.get(Args.scope_type):
            target_dict = hs_dict.setdefault(scope_type, {})
            for scope_str in group.get(Args.scopes):
                target_dict.setdefault(scope_str, {}).update(group.get(Args.hotstrings))
        else:
            hs_dict.setdefault('', {}).update(group.get(Args.hotstrings))
    return hs_dict


def dict_to_ahkcode(hotstrings_data: dict) -> str:
    """From flat scoped dictionary create Autohotkey hotstrings code."""
    hs_global = []
    scope_incl = {}
    scope_excl = {}

    for hotstring, data in hotstrings_data.get('', {}).items():
        line = _make_hotstrings_line(hotstring, data)
        if line:
            hs_global.append(line)

    for key, scope_dict in ((KEY_INCL, scope_incl), (KEY_EXCL, scope_excl)):
        for scope_string, hs_dict in hotstrings_data.get(key, {}).items():
            for scope in scope_string.split('\n'):
                for hotstring, data in hs_dict.items():
                    line = _make_hotstrings_line(hotstring, data)
                    if line:
                        scope_dict.setdefault(scope, []).append(line)

    code = f'{DIRECTIVE_INCL},\n' + '\n'.join(hs_global)
    for directive, scope_dict in ((DIRECTIVE_INCL, scope_incl), (DIRECTIVE_EXCL, scope_excl)):
        for scope, scope_lines in scope_dict.items():
            code += f'\n{directive}, {scope}\n' + '\n'.join(scope_lines)
    return code


def _make_hotstrings_line(hotstring, data):
    text = data.get('text')
    if not text or not hotstring:
        return

    options = ':'
    for opt in Options:
        if data.get(opt.name, False):
            options += opt.value

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
        text = text.replace(':', '`:')
    elif mode == 1:
        if '`n' in text:
            text = '\n' + text.replace('`n', '\n')
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

    return f'{options}:{hotstring}::{text}'


def file_to_dict(path):
    parser = HotstringsParser(path)
    return parser.hs_dict


def iterate(hotstrings_dict):
    """
    Yield scope_mode, scope_string, hotstring, hotstring_cfg.
    """
    for scope_type, data in hotstrings_dict.items():
        if scope_type == '':
            for hotstring, hotstring_cfg in data.items():
                yield '', '', hotstring, hotstring_cfg
        else:
            for scope_mode, scope_mode_data in data.items():
                for scope_string, scope_data in scope_mode_data.items():
                    for hotstring, hotstring_cfg in scope_data.items():
                        yield scope_mode, scope_string, hotstring, hotstring_cfg


class HotstringsParser:
    """
    Autohotkey hotstring code parser
    to create a hotstrings dictionary::

        # '' is the global scope
        {'': {
            'shortcut1': {
                'text': some_string,
                'ignore' True,
                'mode': ...},
            'shortcut2': {...}}

         'scope_incl': {
            'scope_string1': {
                'shortcut1': {...},
                'shortcut2': {...}},
            'scope_string2': {
                'shortcut': {...}}},

         'scope_excl': {...}
    """
    def __init__(self, path):
        self.hs_dict = {'': {}}

        # while parsing parameters
        self.gather_lines = False
        self.hs_buffer = []
        self.this_scope = ''
        self.this_directive = DIRECTIVE_INCL
        self.this_hs = {}
        self.this_shortcut = ''

        self.parse_lines(path)

    def parse_lines(self, path):
        with codecs.open(path, encoding='utf-8-sig') as fobj:
            for line in fobj:
                # cut away comments and strip of whitespace
                stripped = line.split(';', 1)[0].strip()
                if not stripped:
                    continue

                if stripped.startswith('#'):
                    self.handle_scope(stripped)
                elif stripped.startswith(':'):
                    self.handle_hotstring(stripped)
                elif self.gather_lines:
                    if stripped.lower().startswith('return'):
                        self.this_hs['mode'] = 1
                        self.work_buffer()
                        continue
                    # collect the unstripped line
                    self.hs_buffer.append(line.rstrip())

    def handle_scope(self, line):
        self.work_buffer()
        lowline = line.lower()
        if lowline.startswith(DIRECTIVE_INCL):
            self.this_directive = DIRECTIVE_INCL
        elif lowline.startswith(DIRECTIVE_EXCL):
            self.this_directive = DIRECTIVE_EXCL

        scope = line[len(self.this_directive):].strip()
        if scope.startswith(','):
            scope = scope[1:].strip()
        self.this_scope = scope

    def handle_hotstring(self, line):
        self.work_buffer()
        if not '::' in line or not ':' in line[1:]:
            print('Not a hotstring? "%s"' % line)
            return

        self.this_hs = {}
        options, rest = line[1:].split(':', 1)

        # disassemble the options
        options = options.upper()
        for opt in Options:
            if opt.value in options:
                self.this_hs[opt.name] = True
        for name, option_list in OPTION_LISTS.items():
            for i, opt in enumerate(option_list):
                # we do not break because found "C" can still be "C1"
                if opt in options:
                    self.this_hs[name] = i + 1
        for opt, mode_index in RAW_MODES.items():
            if opt in options:
                self.this_hs['mode'] = mode_index
                break

        # if shortcut does not start with :: its easy
        if not rest.startswith('::'):
            self.this_shortcut, text = rest.split('::', 1)
        # otherwise we need to search for the first non-":"
        else:
            for i, letter in enumerate(rest):
                if letter != ':':
                    break
            pos = rest[i:].find('::')
            if pos == -1:
                print('Not a hotstring? "%s"' % line)
                return
            self.this_shortcut = rest[:pos + i]
            text = rest[pos + i + 2:]

        if not text.strip():
            self.gather_lines = True
            self.hs_buffer = []
            return

        self.this_hs['text'] = text
        self.collect()

    def work_buffer(self):
        self.gather_lines = False
        if not self.hs_buffer:
            return
        text = '\n'.join(self.hs_buffer)

        self.this_hs['text'] = text.replace('\r\n', '\n')
        self.collect()

    def collect(self):
        if self.this_hs.get('mode') is None:
            text = self.this_hs['text']
            text = text.replace('`:', ':')
            for char in '!+#^':
                text = text.replace('{%s}' % char, char)
            self.this_hs['text'] = text

        if self.this_scope:
            mode = KEY_EXCL if self.this_directive == DIRECTIVE_EXCL else KEY_INCL
            self.hs_dict.setdefault(mode, {}).setdefault(
                self.this_scope, {})[self.this_shortcut] = self.this_hs
        else:
            self.hs_dict[''][self.this_shortcut] = self.this_hs
        self.this_hs = {}
        self.hs_buffer = []


def scopes_to_groups(cfg: dict) -> bool:
    """Fix incoming dictionary to make sure we use groups
    instead of the oldschool ''-means global/scope_type pattern.
    Or move groups from root to a `groups` dict.

    Return True/False indicating changes were made.
    """
    changed = False
    # loop over root names, we might change length of cfg:
    for name in list(cfg):
        # move implied global scope '' to actual "global" group
        if '' == name:
            _move_group(cfg, '', Args.default)
            changed = True
            continue
        # move each scoped sub group to new group
        if name in IN_EXCLUDE:
            for scope_key in cfg[name].keys():
                new_name = _move_group(cfg, name, scope_key)
                group = cfg[Args.groups][new_name]
                # set scope values
                group[Args.scopes] = [scope_key]
                group[Args.scope_type] = name
                # move hotstrings data out of "scope_key"
                group[Args.hotstrings] = group[Args.hotstrings][scope_key]
            changed = True
            continue
        # move root groups into groups sub dict
        if isinstance(cfg[name], dict) and Args.hotstrings in cfg[name]:
            _move_group(cfg, name, name)
            changed = True
    return changed


def _move_group(cfg: dict, old_name: str, new_name: str) -> str:
    cfg.setdefault(Args.groups, {})
    new_name = a2util.get_next_free_number(new_name, cfg[Args.groups].keys())
    if Args.hotstrings in cfg[old_name]:
        cfg[Args.groups][new_name] = cfg[old_name]
    else:
        cfg[Args.groups][new_name] = {Args.hotstrings: {}}
        cfg[Args.groups][new_name][Args.hotstrings] = cfg[old_name]
    del cfg[old_name]
    return new_name


if __name__ == '__main__':
    import unittest
    import test.test_hotstrings
    unittest.main(test.test_hotstrings, verbosity=2)
