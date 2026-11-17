# Folder Structure Best Practices

## 🎯 Purpose

This guide ensures all team members maintain the clean, organized folder structure established for the SquadMinds Attendance System.

## 📐 Architecture Overview

### Clean Architecture Layers

```
┌─────────────────────────────────────────┐
│         Presentation Layer              │
│   (UI, Screens, Widgets, Providers)     │
└─────────────────┬───────────────────────┘
                  │
┌─────────────────▼───────────────────────┐
│          Domain Layer                   │
│   (Business Logic, Use Cases, Rules)    │
└─────────────────┬───────────────────────┘
                  │
┌─────────────────▼───────────────────────┐
│           Data Layer                    │
│  (Repositories, Data Sources, Models)   │
└─────────────────────────────────────────┘
```

### Dependency Rule
- **Outer layers depend on inner layers**
- **Inner layers never depend on outer layers**
- **Domain layer is independent of frameworks**

## 📁 When to Create New Folders

### ✅ Create a folder when:
1. You have **3 or more related files**
2. Creating a **new feature module**
3. Adding a **new category** of components
4. Organizing **reusable utilities**

### ❌ Don't create a folder when:
1. You have only **1-2 files**
2. Files are **better placed** in existing folders
3. Creating **temporary/experimental** code
4. Making a **one-off utility**

## 🗂️ File Placement Guidelines

### Core Layer (`lib/core/`)

#### `core/config/`
**When to use**: App-wide configuration, environment setup
```dart
// ✅ Good
core/config/supabase_config.dart
core/config/api_config.dart
core/config/env_config.dart

// ❌ Bad
core/config/login_config.dart  // Feature-specific, should be in feature folder
```

#### `core/constants/`
**When to use**: App-wide constants, enums
```dart
// ✅ Good
core/constants/app_constants.dart
core/constants/enums.dart
core/constants/api_endpoints.dart

// ❌ Bad
core/constants/login_constants.dart  // Feature-specific
```

#### `core/services/`
**When to use**: Platform services, third-party integrations
```dart
// ✅ Good
core/services/biometric_service.dart
core/services/notification_service.dart
core/services/location_service.dart

// ❌ Bad
core/services/user_service.dart  // Business logic, should be in domain
```

#### `core/theme/`
**When to use**: Design system, themes, styling
```dart
// ✅ Good
core/theme/app_theme.dart
core/theme/colors.dart
core/theme/text_styles.dart

// ❌ Bad
core/theme/login_theme.dart  // Screen-specific styling
```

#### `core/utils/`
**When to use**: Helper functions, utilities
```dart
// ✅ Good
core/utils/logger.dart
core/utils/date_formatter.dart
core/utils/validator.dart

// ❌ Bad
core/utils/user_utils.dart  // Feature-specific logic
```

#### `core/widgets/`
**When to use**: Reusable widgets used across multiple features
```dart
// ✅ Good
core/widgets/glass_card.dart
core/widgets/loading_indicator.dart
core/widgets/custom_button.dart

// ❌ Bad
core/widgets/login_form.dart  // Feature-specific widget
```

### Data Layer (`lib/data/`)

#### `data/datasources/remote/`
**When to use**: API clients, remote data sources
```dart
// ✅ Good
data/datasources/remote/supabase_datasource.dart
data/datasources/remote/fastapi_datasource.dart
data/datasources/remote/attendance_remote_datasource.dart

// Local datasources
data/datasources/local/cache_datasource.dart
data/datasources/local/secure_storage_datasource.dart
```

#### `data/models/`
**When to use**: Data transfer objects, API response models
```dart
// ✅ Good
data/models/user_model.dart
data/models/attendance_model.dart
data/models/leave_model.dart

// ❌ Bad (use entities in domain instead)
data/models/user_entity.dart
```

#### `data/repositories/`
**When to use**: Repository implementations
```dart
// ✅ Good
data/repositories/auth_repository_impl.dart
data/repositories/attendance_repository_impl.dart

// Must implement interfaces from domain/repositories/
```

### Domain Layer (`lib/domain/`)

#### `domain/entities/`
**When to use**: Business objects, domain models
```dart
// ✅ Good
domain/entities/user.dart
domain/entities/attendance.dart
domain/entities/leave_request.dart

// These are pure business objects with no framework dependencies
```

#### `domain/repositories/`
**When to use**: Repository interfaces (contracts)
```dart
// ✅ Good
domain/repositories/auth_repository.dart
domain/repositories/attendance_repository.dart

// These are abstract classes defining contracts
```

#### `domain/usecases/`
**When to use**: Business logic, use cases
```dart
// ✅ Good
domain/usecases/login_user.dart
domain/usecases/mark_attendance.dart
domain/usecases/request_leave.dart

// One class per use case, single responsibility
```

### Presentation Layer (`lib/presentation/`)

#### `presentation/providers/`
**When to use**: State management providers (Riverpod)
```dart
// ✅ Good
presentation/providers/auth_provider.dart
presentation/providers/attendance_provider.dart
presentation/providers/theme_provider.dart
```

#### `presentation/screens/[feature]/`
**When to use**: Feature-specific screens and widgets
```dart
// ✅ Good Structure
presentation/screens/
├── auth/
│   ├── login_screen.dart
│   ├── signup_screen.dart
│   └── widgets/
│       ├── login_form.dart
│       └── social_login_buttons.dart
├── attendance/
│   ├── check_in_screen.dart
│   ├── attendance_history_screen.dart
│   └── widgets/
│       ├── attendance_card.dart
│       └── check_in_button.dart
└── profile/
    ├── profile_screen.dart
    ├── edit_profile_screen.dart
    └── widgets/
        └── profile_header.dart
```

## 🎨 Naming Conventions

### Files
```dart
// ✅ Good - snake_case
login_screen.dart
user_profile_widget.dart
attendance_repository_impl.dart

// ❌ Bad
LoginScreen.dart  // PascalCase
login-screen.dart  // kebab-case
loginScreen.dart  // camelCase
```

### Classes
```dart
// ✅ Good - PascalCase
class LoginScreen extends StatelessWidget {}
class UserProfileWidget extends StatefulWidget {}
class AttendanceRepositoryImpl implements AttendanceRepository {}

// ❌ Bad
class loginScreen {}  // camelCase
class login_screen {}  // snake_case
```

### Variables & Functions
```dart
// ✅ Good - camelCase
final userName = 'John';
void getUserData() {}
bool isLoggedIn = false;

// ❌ Bad
final user_name = 'John';  // snake_case
final UserName = 'John';  // PascalCase
```

### Constants
```dart
// ✅ Good - SCREAMING_SNAKE_CASE or camelCase for private
const int MAX_LOGIN_ATTEMPTS = 3;
const String API_BASE_URL = 'https://api.example.com';
const _defaultTimeout = Duration(seconds: 30);

// ❌ Bad
const int maxLoginAttempts = 3;  // camelCase for public constants
const String apiBaseUrl = 'https://api.example.com';
```

### Private Members
```dart
// ✅ Good - prefix with underscore
class _InternalWidget extends StatelessWidget {}
void _privateMethod() {}
final _privateVariable = 'secret';

// Use for implementation details not exposed outside the file
```

## 📦 Import Organization

### Order
1. Dart SDK imports
2. Flutter imports
3. Package imports
4. Relative imports

```dart
// ✅ Good
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:attendence/core/theme/app_theme.dart';

import 'widgets/login_form.dart';

// ❌ Bad - mixed order
import 'package:attendence/core/theme/app_theme.dart';
import 'dart:async';
import 'widgets/login_form.dart';
import 'package:flutter/material.dart';
```

### Use Absolute Imports
```dart
// ✅ Good - absolute from package root
import 'package:attendence/core/theme/app_theme.dart';
import 'package:attendence/presentation/screens/auth/login_screen.dart';

// ❌ Bad - relative imports
import '../../core/theme/app_theme.dart';
import '../auth/login_screen.dart';
```

## 🎯 Feature Organization

### Option 1: By Layer (Current Structure)
```
lib/
├── data/
│   └── [all data layer code]
├── domain/
│   └── [all domain layer code]
└── presentation/
    └── [all presentation layer code]
```

**Pros**: Clear separation of concerns
**Cons**: Feature code is spread across folders

### Option 2: By Feature (Alternative)
```
lib/
└── features/
    ├── auth/
    │   ├── data/
    │   ├── domain/
    │   └── presentation/
    └── attendance/
        ├── data/
        ├── domain/
        └── presentation/
```

**Pros**: Feature code is colocated
**Cons**: Core utilities need special handling

## 🧹 Keep It Clean

### Daily Habits
- ✅ Delete unused imports
- ✅ Remove commented code
- ✅ Fix lint warnings
- ✅ Update documentation
- ✅ Run `flutter analyze`

### Weekly Review
- ✅ Check for duplicate code
- ✅ Refactor long files (>500 lines)
- ✅ Update dependencies
- ✅ Review folder structure
- ✅ Clean up test files

### Monthly Cleanup
- ✅ Remove deprecated code
- ✅ Archive old features
- ✅ Update documentation
- ✅ Performance audit
- ✅ Dependency audit

## 🚫 Anti-Patterns to Avoid

### 1. God Classes
```dart
// ❌ Bad - One massive file with everything
// user_manager.dart (2000 lines)
class UserManager {
  void login() {}
  void logout() {}
  void updateProfile() {}
  void resetPassword() {}
  void deleteAccount() {}
  void getHistory() {}
  // ... 50 more methods
}

// ✅ Good - Separate concerns
// auth_service.dart
class AuthService {
  void login() {}
  void logout() {}
}

// profile_service.dart
class ProfileService {
  void updateProfile() {}
}
```

### 2. Deep Nesting
```dart
// ❌ Bad
lib/presentation/screens/user/profile/settings/privacy/data/widgets/card.dart

// ✅ Good
lib/presentation/screens/profile/widgets/privacy_card.dart
```

### 3. Mixed Responsibilities
```dart
// ❌ Bad - UI and business logic mixed
class LoginScreen extends StatelessWidget {
  void login(String email, String password) {
    // Business logic in UI layer
    if (email.isEmpty) return;
    final hashedPassword = hashPassword(password);
    api.login(email, hashedPassword);
  }
}

// ✅ Good - Separate concerns
// presentation/screens/auth/login_screen.dart
class LoginScreen extends ConsumerWidget {
  void _onLoginPressed() {
    ref.read(authProvider.notifier).login(email, password);
  }
}

// domain/usecases/login_user.dart
class LoginUser {
  Future<Either<Failure, User>> call(String email, String password) {
    // Business logic here
  }
}
```

### 4. Circular Dependencies
```dart
// ❌ Bad
// auth_service.dart
import 'user_service.dart';

// user_service.dart
import 'auth_service.dart';

// ✅ Good - Use interfaces/abstract classes
// domain/repositories/auth_repository.dart
abstract class AuthRepository {}

// data/repositories/auth_repository_impl.dart
class AuthRepositoryImpl implements AuthRepository {}
```

## 📋 Checklist for New Code

Before committing:
- [ ] File is in the correct folder
- [ ] Follows naming conventions
- [ ] Imports are organized
- [ ] No unused imports
- [ ] No magic numbers/strings
- [ ] Constants are in appropriate place
- [ ] Reusable code is in `core/`
- [ ] Business logic is in `domain/`
- [ ] UI code is in `presentation/`
- [ ] `flutter analyze` passes
- [ ] Documentation is updated

## 🎓 Learning Resources

### Clean Architecture
- [The Clean Architecture by Uncle Bob](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [Flutter Clean Architecture Guide](https://resocoder.com/flutter-clean-architecture-tdd/)

### Flutter Best Practices
- [Effective Dart](https://dart.dev/guides/language/effective-dart)
- [Flutter Style Guide](https://github.com/flutter/flutter/wiki/Style-guide-for-Flutter-repo)

### State Management
- [Riverpod Documentation](https://riverpod.dev/)
- [Flutter State Management](https://flutter.dev/docs/development/data-and-backend/state-mgmt)

## 💡 Tips for Success

1. **Think in features**: Group related code together
2. **Keep it simple**: Don't over-engineer the structure
3. **Be consistent**: Follow established patterns
4. **Refactor early**: Don't let technical debt accumulate
5. **Document decisions**: Update this guide when structure evolves

---

**Remember**: A well-organized codebase is easier to maintain, test, and scale!
