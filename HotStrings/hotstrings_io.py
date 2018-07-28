# -*- coding: utf-8 -*-
import os
import a2util
import a2ctrl
from PySide2 import QtWidgets
from a2element import DrawCtrl, EditCtrl
from a2widget.a2item_editor import A2ItemEditor
from a2widget import A2TextField


KEY_MAP = {'instant': '*',
           'ignore': 'O',
           'inside': '?',
           'append': 'B0',
           'raw': 'R',
           'textmode': 'T'}


def dict_to_hotstrings(hotstrings_data):
    lines = []
    for hotstring, data in hotstrings_data.items():
        text = data.get('text')
        if not text or not hotstring:
            continue

        raw_mode = False
        option = ':'
        for key, char in KEY_MAP.items():
            if data.get(key, False):
                if key in ['raw', 'textmode']:
                    raw_mode = True
                option += char
        case = data.get('case')
        if case == 1:
            option += 'C'
        elif case == 2:
            option += 'C1'

        option += ':'

        text = text.replace('\n', '`n')
        if not data.get('origmode', False) and not raw_mode:
            for char in '!+#^':
                text = text.replace(char, '{%s}' % char)

        lines.append(f'{option}{hotstring}::{text}')

    lines = ['#IfWinActive,'] + lines
    return '\n'.join(lines)


def hotstrings_to_dict(hotstrings_code):
    for line in hotstrings_code.split('\n'):
        if not line.startswith(':'):
            continue

