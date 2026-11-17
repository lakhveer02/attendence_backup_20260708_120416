# SquadMinds Attendance System

A comprehensive Flutter-based attendance management system with biometric authentication, location tracking, and real-time analytics.

## 🚀 Quick Start

### Prerequisites
- Flutter SDK (^3.7.0)
- Python 3.14+ (for backend)
- Supabase account
- Google Maps API key

### Setup Instructions

1. **Clone and Install Dependencies**
   ```bash
   # Flutter dependencies
   flutter pub get
   
   # Backend dependencies
   cd fastapi-backend
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   pip install -r requirements.txt
   ```

2. **Configure Environment Variables**
   - Copy `.env.example` to `.env` (in fastapi-backend)
   - Add your Supabase credentials and API keys

3. **Database Setup**
   - See `fastapi-backend/DATABASE_SETUP_GUIDE.md` for complete setup
   - Run SQL scripts in `fastapi-backend/sql/` directory

4. **Run the Application**
   ```bash
   # Start backend
   cd fastapi-backend
   uvicorn main:app --reload
   
   # Run Flutter app
   flutter run
   ```

## 📱 Features

### Core Functionality
- **Multi-factor Authentication**: Email/password, biometric (fingerprint/face ID)
- **Smart Attendance**: Check-in/out with location verification and geofencing
- **Real-time Tracking**: Live employee status and location monitoring
- **Leave Management**: Request, approve, and track leave applications
- **Analytics & Reports**: Comprehensive attendance analytics with charts
- **Role-based Access**: Admin, Manager, HR, and Employee roles

### Advanced Features
- Face recognition for attendance
- QR code check-in
- NFC badge support
- Offline mode with sync
- Push notifications
- PDF report generation
- Video/audio calls (Agora integration)
- Real-time updates via WebSockets

## 🏗️ Architecture

The app follows Clean Architecture with clear separation of concerns:

```
lib/
├── core/              # Core utilities, services, theme
│   ├── config/        # App configuration
│   ├── constants/     # Constants and enums
│   ├── error/         # Error handling
│   ├── routing/       # Navigation
│   ├── services/      # Platform services (biometric, permissions, notifications)
│   ├── theme/         # Design system and themes
│   ├── utils/         # Helper utilities
│   └── widgets/       # Reusable UI components
├── data/              # Data layer
│   ├── datasources/   # Remote data sources (Supabase, FastAPI)
│   ├── models/        # Data models
│   └── repositories/  # Repository implementations
├── domain/            # Business logic layer
├── presentation/      # UI layer (screens, widgets)
└── screens/           # Feature screens
    ├── auth/          # Authentication screens
    └── main/          # Main app screens
```

## 🔧 Technology Stack

### Frontend (Flutter)
- **State Management**: Riverpod
- **Backend Services**: Supabase, FastAPI
- **Maps**: Google Maps
- **Biometrics**: local_auth, face detection
- **Charts**: fl_chart, Syncfusion
- **Real-time**: WebSockets, Socket.io
- **Video Calls**: Agora RTC

### Backend (FastAPI)
- **Framework**: FastAPI
- **Database**: PostgreSQL (via Supabase)
- **Authentication**: JWT, OAuth2
- **Image Processing**: OpenCV, face_recognition
- **PDF Generation**: ReportLab

## 📋 Project Status

### ✅ Completed
- Authentication system with multiple providers
- Biometric authentication
- Location-based attendance
- Real-time dashboard
- Leave management
- Reports and analytics
- Role-based access control

### 🚧 In Progress
- Enhanced face recognition accuracy
- Offline mode improvements
- Advanced analytics dashboards

## 🔐 Permissions Required

### iOS (Info.plist)
- Camera access (face recognition)
- Location access (geofencing)
- Biometric authentication (Face ID/Touch ID)
- Photo library access

### Android (AndroidManifest.xml)
- Camera
- Location (fine and coarse)
- Biometric
- NFC
- Internet

## 📖 Documentation

- **Backend Setup**: `fastapi-backend/SETUP_GUIDE.md`
- **Database Guide**: `fastapi-backend/DATABASE_SETUP_GUIDE.md`
- **API Documentation**: Run backend and visit `/docs` endpoint
- **Testing Guide**: `TEST_CHECKLIST.md`

## 🐛 Troubleshooting

### Common Issues

1. **Biometric Authentication Not Working**
   - Ensure device has biometric hardware
   - Check permissions in system settings
   - See `BIOMETRIC_SETUP_GUIDE.md`

2. **Location Services Issues**
   - Enable location services in device settings
   - Grant location permissions to the app
   - Check geofence configuration

3. **Backend Connection Failed**
   - Verify backend is running
   - Check API endpoint URLs in `.env`
   - Ensure Supabase credentials are correct

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## 📄 License

This project is proprietary and confidential.

## 👥 Team

Developed by SquadMinds Team

## 📞 Support

For issues and questions, please contact the development team.
