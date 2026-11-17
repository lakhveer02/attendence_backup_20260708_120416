#!/usr/bin/env python3
import re
from pathlib import Path

root = Path('lib')
if not root.exists():
    print('lib/ not found')
    raise SystemExit(1)

replacements = [
    (re.compile(r"\bAppColors\.background\b"), 'AppColors.surface'),
    (re.compile(r"\bonBackground\b"), 'onSurface'),
    (re.compile(r"\bactiveColor\b"), 'activeThumbColor'),
]

patched_files = []
for path in root.rglob('*.dart'):
    text = path.read_text(encoding='utf-8')
    new = text
    for pattern, repl in replacements:
        new = pattern.sub(repl, new)
    if new != text:
        path.write_text(new, encoding='utf-8')
        patched_files.append(str(path))

print(f'Patched {len(patched_files)} files')
for p in patched_files:
    print(p)
