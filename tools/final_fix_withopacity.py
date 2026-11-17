#!/usr/bin/env python3
"""
Final comprehensive fix for all remaining .withOpacity() calls.
Replaces with .withValues(alpha: ...) for proper Material 3 support.
"""

import os
import re
from pathlib import Path

def fix_withopacity_comprehensive():
    """Replace all .withOpacity() calls with .withValues() equivalents."""
    lib_dir = Path("lib")
    files_processed = 0
    replacements_made = 0

    for dart_file in lib_dir.rglob("*.dart"):
        try:
            with open(dart_file, "r", encoding="utf-8") as f:
                content = f.read()

            original = content

            # Pattern 1: .withOpacity(0.XX) - convert opacity to alpha (0-1 range)
            # Example: .withOpacity(0.5) -> .withValues(alpha: 0.5)
            def replace_withopacity(match):
                opacity_value = match.group(1)
                return f".withValues(alpha: {opacity_value})"

            # Find and replace all .withOpacity(...) patterns
            content = re.sub(r"\.withOpacity\(([^)]+)\)", replace_withopacity, content)

            if content != original:
                files_processed += 1
                # Count replacements
                count = len(re.findall(r"\.withValues\(alpha:", content)) - len(re.findall(r"\.withValues\(alpha:", original))
                replacements_made += count

                with open(dart_file, "w", encoding="utf-8") as f:
                    f.write(content)
                print(f"✓ Fixed: {dart_file.relative_to('.')}")

        except Exception as e:
            print(f"✗ Error processing {dart_file}: {e}")

    print(f"\n=== Summary ===")
    print(f"Files processed: {files_processed}")
    print(f"Replacements made: {replacements_made}")
    return files_processed, replacements_made

if __name__ == "__main__":
    fix_withopacity_comprehensive()
