#!/usr/bin/env python3
from pathlib import Path
import re

p = Path('lib/core/theme/app_theme.dart')
s = p.read_text()

def fix_color_scheme_block(text, ctor):
    start = text.find(ctor)
    if start == -1:
        return text, 0
    i = start + len(ctor)
    # find '('
    while i < len(text) and text[i] != '(':
        i += 1
    if i>=len(text):
        return text, 0
    # find matching closing paren
    j = i+1
    depth = 1
    while j < len(text) and depth>0:
        if text[j] == '(':
            depth +=1
        elif text[j] == ')':
            depth -=1
        j+=1
    block = text[i+1:j-1]
    parts = []
    cur = ''
    depth2 = 0
    for ch in block:
        if ch=='(':
            depth2+=1
            cur+=ch
        elif ch==')':
            depth2-=1
            cur+=ch
        elif ch==',' and depth2==0:
            parts.append(cur.strip())
            cur=''
        else:
            cur+=ch
    if cur.strip():
        parts.append(cur.strip())
    seen = set()
    newparts = []
    removed = 0
    for part in parts:
        m = re.match(r"([a-zA-Z0-9_]+)\s*:\s*(.*)", part, re.S)
        if m:
            key = m.group(1)
            if key=='background':
                removed+=1
                continue
            if key in seen:
                removed+=1
                continue
            seen.add(key)
            newparts.append(part)
        else:
            newparts.append(part)
    newblock = ',\n        '.join(newparts)
    newtext = text[:i+1] + '\n        ' + newblock + '\n      ' + text[j-1:]
    return newtext, removed

text = s
removed_total = 0
for ctor in ['ColorScheme.light', 'ColorScheme.dark']:
    # loop until no more occurrences
    while True:
        newtext, removed = fix_color_scheme_block(text, ctor)
        if removed==0:
            break
        text = newtext
        removed_total += removed

p.write_text(text)
print('Done. removed entries:', removed_total)
