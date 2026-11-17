# Project Structure Documentation

This document outlines the clean, organized folder structure of the SquadMinds Attendance System.

## 📁 Root Directory Structure

```
attendence/
├── android/                  # Android native platform code
├── ios/                      # iOS native platform code
├── linux/                    # Linux platform code (optional)
├── macos/                    # macOS platform code (optional)
├── windows/                  # Windows platform code (optional)
├── web/                      # Web platform code (optional)
├── lib/                      # Main Flutter application code
├── fastapi-backend/          # Python FastAPI backend service
├── assets/                   # Static assets (images, fonts, etc.)
├── docs/                     # Documentation files
├── presentation/             # Design mockups and presentations
├── tools/                    # Development tools and scripts
├── build/                    # Build output (gitignored)
├── .dart_tool/              # Dart tooling (gitignored)
├── pubspec.yaml             # Flutter dependencies
├── README.md                # Main project documentation
├── .gitignore               # Git ignore rules
├── .env.example             # Environment variables template
├── docker-compose.yml       # Docker compose configuration
└── firebase.json            # Firebase configuration
```

## 📱 Flutter App Structure (`lib/`)

The Flutter app follows **Clean Architecture** principles with clear separation of concerns:

```
lib/
├── core/                           # Core utilities and services
│   ├── config/                    # App configuration
│   │   └── supabase_config.dart
│   ├── constants/                 # Constants and enums
│   │   ├── app_constants.dart
│   │   └── enums.dart
│   ├── error/                     # Error handling
│   │   ├── exceptions.dart
│   │   ├── failures.dart
│   │   └── failures.freezed.dart
│   ├── routing/                   # Navigation
│   │   └── app_router.dart
│   ├── services/                  # Platform services
│   │   ├── biometric_service.dart
│   │   ├── permission_service.dart
│   │   └── notification_service.dart
│   ├── theme/                     # Design system and themes
│   │   ├── app_theme.dart
│   │   ├── app_text_styles.dart
│   │   ├── unified_theme.dart
│   │   ├── design_system.dart
│   │   ├── glassmorphic_widgets.dart
│   │   └── role_based_colors.dart
│   ├── utils/                     # Helper utilities
│   │   ├── logger.dart
│   │   ├── permission_utils.dart
│   │   ├── device_info_utils.dart
│   │   └── responsive_utils.dart
│   └── widgets/                   # Reusable UI components
│       ├── glass_card.dart
│       ├── glass_bottom_nav.dart
│       ├── accessibility_widgets.dart
│       └── premium_components.dart
│
├── data/                          # Data layer
│   ├── datasources/              # Data sources
│   │   └── remote/               # Remote API sources
│   │       ├── supabase_datasource.dart
│   │       ├── fastapi_datasource.dart
│   │       ├── attendance_remote_datasource.dart
│   │       └── role_management_datasource.dart
│   ├── models/                   # Data models
│   │   ├── profile_model.dart
│   │   ├── profile_model.freezed.dart
│   │   ├── attendance_model.dart
│   │   ├── leave_model.dart
│   │   ├── leave_model.g.dart
│   │   └── department_model.freezed.dart
│   └── repositories/             # Repository implementations
│       ├── attendance_repository_impl.dart
│       └── fastapi_auth_repository_impl.dart
│
├── domain/                        # Business logic layer
│   ├── entities/                 # Business entities
│   ├── repositories/             # Repository interfaces
│   └── usecases/                 # Business use cases
│
├── presentation/                  # UI/Presentation layer
│   ├── providers/                # Riverpod providers
│   │   └── auth_provider.dart
│   └── screens/                  # Feature screens
│       ├── splash/               # Splash screen
│       ├── auth/                 # Authentication screens
│       │   ├── login_screen.dart
│       │   ├── premium_signup_screen.dart
│       │   ├── biometric_enrollment_screen.dart
│       │   └── force_password_reset_screen.dart
│       ├── home/                 # Home/dashboard screens
│       ├── admin/                # Admin-specific screens
│       ├── attendance/           # Attendance management
│       ├── leave/                # Leave management
│       ├── profile/              # User profile
│       ├── payroll/              # Payroll management
│       ├── onboarding/           # User onboarding
│       └── testing/              # Testing screens (dev only)
│
├── firebase_options.dart         # Firebase configuration
└── main.dart                     # App entry point
```

## 🐍 Backend Structure (`fastapi-backend/`)

```
fastapi-backend/
├── app/                          # Main application code
│   ├── api/                     # API endpoints
│   ├── core/                    # Core backend utilities
│   ├── models/                  # Database models
│   ├── services/                # Business logic services
│   └── utils/                   # Helper utilities
├── migrations/                   # Database migrations
├── sql/                         # SQL scripts
│   └── FIX_RLS_PERMISSIONS.sql
├── tests/                       # Backend tests
├── venv/                        # Python virtual environment (gitignored)
├── main.py                      # FastAPI entry point
├── requirements.txt             # Python dependencies
├── .env                         # Environment variables (gitignored)
├── DATABASE_SETUP_GUIDE.md     # Database setup instructions
├── SETUP_GUIDE.md              # Backend setup guide
└── docker-compose.yml          # Docker configuration
```

## 📚 Documentation (`docs/`)

```
docs/
├── BIOMETRIC_SETUP_GUIDE.md     # Biometric feature setup
├── QUICK_START_GUIDE.md         # Quick start instructions
├── TEST_CHECKLIST.md            # Testing checklist
└── PROJECT_STRUCTURE.md         # This file
```

## 🎨 Assets Structure

```
assets/
└── images/
    └── logo.svg                 # App logo
```

## 🎯 Key Architectural Decisions

### 1. **Clean Architecture**
- **Core Layer**: Framework-independent business logic and utilities
- **Data Layer**: Data sources, models, and repository implementations
- **Domain Layer**: Business entities and use cases
- **Presentation Layer**: UI components and state management

### 2. **State Management**
- Using **Riverpod** for state management
- Providers are located in `lib/presentation/providers/`

### 3. **Code Generation**
- **Freezed**: For immutable data classes (`*.freezed.dart`)
- **JSON Serializable**: For JSON serialization (`*.g.dart`)
- **Riverpod Generator**: For provider generation

### 4. **Backend Architecture**
- **FastAPI**: Modern Python web framework
- **PostgreSQL**: Via Supabase for database
- **JWT**: For authentication tokens
- **Clean separation**: API, services, models, and utilities

## 🗂️ Folder Naming Conventions

- **snake_case**: For file names (`login_screen.dart`)
- **PascalCase**: For class names (`LoginScreen`)
- **camelCase**: For variables and functions (`userName`, `getUserData()`)
- **SCREAMING_SNAKE_CASE**: For constants (`MAX_LOGIN_ATTEMPTS`)

## 🚫 Removed/Deprecated

The following were removed during cleanup:
- ✅ Duplicate documentation files (consolidated into README.md)
- ✅ Legacy `lib/screens/` folder (replaced by `lib/presentation/screens/`)
- ✅ Unused `lib/tools/mockup_exporter.dart` (moved to development tools)
- ✅ Duplicate `.venv` in root (kept only in `fastapi-backend/`)
- ✅ Temporary files (`*.jpeg`, `.DS_Store`)
- ✅ Redundant markdown files

## 📝 File Organization Best Practices

1. **One feature per folder**: Group related files together
2. **Separation of concerns**: UI, business logic, and data access are separate
3. **Reusability**: Common widgets and utilities are in `core/`
4. **Testability**: Clear architecture makes unit testing easier
5. **Scalability**: New features can be added without restructuring

## 🔄 Import Path Convention

Always use absolute imports from the package root:

```dart
// ✅ Good
import 'package:attendence/core/theme/app_theme.dart';
import 'package:attendence/presentation/screens/auth/login_screen.dart';

// ❌ Bad
import '../../core/theme/app_theme.dart';
import '../auth/login_screen.dart';
```

## 🎯 Next Steps for Maintenance

1. **Keep documentation updated**: Update this file when structure changes
2. **Follow conventions**: Maintain consistent naming and organization
3. **Regular cleanup**: Remove unused code and dependencies
4. **Code generation**: Run `flutter pub run build_runner build` after model changes
5. **Dependency updates**: Regularly update `pubspec.yaml` and `requirements.txt`

---

Last Updated: July 7, 2026
