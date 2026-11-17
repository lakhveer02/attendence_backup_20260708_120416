#!/usr/bin/env python3
import re
import sys
from pathlib import Path

root = Path('lib')
if not root.exists():
    print('lib/ not found')
    sys.exit(1)

pattern = re.compile(r"\.withOpacity\(\s*([^\)]+)\s*\)")
count = 0
for path in root.rglob('*.dart'):
    text = path.read_text(encoding='utf-8')
    new = pattern.sub(r'.withValues(alpha:\1)', text)
    if new != text:
        path.write_text(new, encoding='utf-8')
        print(f'Patched {path}')
        count += 1

print(f'Done. Files patched: {count}')
