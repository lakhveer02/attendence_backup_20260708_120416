#!/usr/bin/env python3
from pathlib import Path

# Remove unnecessary dart:ui imports
files_with_unused_ui = [
    'lib/presentation/screens/admin/team_overview_screen.dart',
    'lib/presentation/screens/attendance/premium_attendance_analytics_screen.dart',
    'lib/presentation/screens/attendance/premium_attendance_dashboard_screen.dart',
    'lib/presentation/screens/leave/leave_management_screen.dart',
]

for fpath in files_with_unused_ui:
    p = Path(fpath)
    if p.exists():
        s = p.read_text()
        s = s.replace("import 'dart:ui';\n", "")
        s = s.replace("import 'dart:ui'; ", "")
        p.write_text(s)
        print(f'Removed dart:ui import from {fpath}')

# Remove unused _slideAnimation field from splash_screen.dart
p = Path('lib/screens/auth/splash_screen.dart')
if p.exists():
    s = p.read_text()
    # Find and remove the _slideAnimation field
    s = s.replace('  late final AnimationController _slideAnimation;\n', '')
    p.write_text(s)
    print('Removed unused _slideAnimation field')

# Remove unused isDark var from premium_components.dart
p = Path('lib/core/widgets/premium_components.dart')
if p.exists():
    s = p.read_text()
    # Replace the full line assignment
    lines = s.split('\n')
    new_lines = []
    for line in lines:
        if 'final isDark = ' in line and 'unused_local_variable' not in line:
            # Keep the line but comment it or remove it
            if "MediaQuery.of(context).platformBrightness == Brightness.dark" in line:
                new_lines.append('    // final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;')
            else:
                new_lines.append(line)
        else:
            new_lines.append(line)
    p.write_text('\n'.join(new_lines))
    print('Handled unused isDark variable')

print('Done')
