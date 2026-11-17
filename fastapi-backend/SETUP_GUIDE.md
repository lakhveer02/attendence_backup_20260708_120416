# 🚀 FastAPI Backend Setup Guide

## Complete Implementation - All Features Working

This backend provides full REST API support for the Attendance App with:
- ✅ Authentication (Login, Signup)
- ✅ Attendance Management (Check-in, Check-out, History)
- ✅ Leave Management (Apply, Approve, Track)
- ✅ Face Recognition (Enroll, Verify, Liveness)
- ✅ Profile Management
- ✅ Dashboard Analytics
- ✅ Department Management
- ✅ Real-time Stats

---

## 📋 Prerequisites

- Python 3.10 or higher
- Supabase account with database setup
- pip or conda package manager

---

## 🔧 Quick Setup (5 Minutes)

### 1. Install Dependencies

```bash
cd fastapi-backend

# Create virtual environment (recommended)
python -m venv venv

# Activate virtual environment
# On macOS/Linux:
source venv/bin/activate
# On Windows:
venv\Scripts\activate

# Install all packages
pip install -r requirements.txt
```

### 2. Configure Environment

```bash
# Copy example environment file
cp .env.example .env

# Edit .env with your values
nano .env  # or use any text editor
```

**Required Environment Variables:**
```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your_anon_key
SUPABASE_SERVICE_KEY=your_service_role_key
SECRET_KEY=your_random_secret_key_here
```

### 3. Run the Server

```bash
# From fastapi-backend directory
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

# Or using Python directly
python -m uvicorn app.main:app --reload
```

**Server will start at:** `http://localhost:8000`

---

## 📚 API Documentation

Once the server is running, visit:

- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc
- **OpenAPI JSON**: http://localhost:8000/openapi.json

---

## 🔌 API Endpoints

### Authentication
```
POST   /api/v1/auth/signup       # Create new account
POST   /api/v1/auth/login        # Login
```

### Attendance
```
POST   /api/v1/attendance/check-in     # Check in to work
PUT    /api/v1/attendance/check-out    # Check out from work
GET    /api/v1/attendance/{profile_id} # Get attendance history
GET    /api/v1/attendance/today/{profile_id} # Today's attendance
GET    /api/v1/attendance/summary/{profile_id} # Attendance stats
```

### Leave Management
```
POST   /api/v1/leaves               # Apply for leave
GET    /api/v1/leaves/{profile_id}  # Get leave requests
GET    /api/v1/leaves/pending       # Pending requests (Admin)
PUT    /api/v1/leaves/{id}/approve  # Approve/reject leave
```

### Profile
```
GET    /api/v1/profiles/{id}   # Get profile
GET    /api/v1/profiles        # Get all profiles (Admin)
PUT    /api/v1/profiles/{id}   # Update profile
```

### Face Recognition
```
POST   /api/v1/faces/enroll    # Enroll face
POST   /api/v1/faces/verify    # Verify face
```

### Dashboard & Analytics
```
GET    /api/v1/dashboard/stats # Dashboard statistics
```

### Departments
```
GET    /api/v1/departments     # List departments
POST   /api/v1/departments     # Create department
```

---

## 🧪 Testing the API

### Using curl

**1. Sign Up:**
```bash
curl -X POST http://localhost:8000/api/v1/auth/signup \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "password123",
    "full_name": "John Doe",
    "role": "employee"
  }'
```

**2. Login:**
```bash
curl -X POST http://localhost:8000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "password123"
  }'
```

**3. Check In:**
```bash
curl -X POST http://localhost:8000/api/v1/attendance/check-in \
  -H "Content-Type: application/json" \
  -d '{
    "profile_id": "your-profile-id",
    "check_in_gps": {
      "latitude": 37.7749,
      "longitude": -122.4194
    },
    "is_wfh": false,
    "verification_method": "face",
    "device_id": "device123"
  }'
```

### Using Python requests

```python
import requests

BASE_URL = "http://localhost:8000/api/v1"

# Sign up
response = requests.post(f"{BASE_URL}/auth/signup", json={
    "email": "user@example.com",
    "password": "password123",
    "full_name": "John Doe",
    "role": "employee"
})
print(response.json())

# Login
response = requests.post(f"{BASE_URL}/auth/login", json={
    "email": "user@example.com",
    "password": "password123"
})
user_data = response.json()
profile_id = user_data["user"]["id"]

# Check in
response = requests.post(f"{BASE_URL}/attendance/check-in", json={
    "profile_id": profile_id,
    "check_in_gps": {"latitude": 37.7749, "longitude": -122.4194},
    "is_wfh": False,
    "verification_method": "face",
    "device_id": "device123"
})
print(response.json())
```

---

## 🔗 Connect Flutter App

### Update Flutter App Constants

Edit `lib/core/constants/app_constants.dart`:

```dart
class AppConstants {
  // For iOS Simulator / Android Emulator on same machine
  static const String baseUrl = 'http://localhost:8000/api/v1';
  
  // For physical device on same network
  // static const String baseUrl = 'http://YOUR_LOCAL_IP:8000/api/v1';
  // Example: 'http://192.168.1.100:8000/api/v1'
  
  // For production
  // static const String baseUrl = 'https://your-api.com/api/v1';
}
```

### Find Your Local IP (for physical devices)

**macOS/Linux:**
```bash
ifconfig | grep "inet " | grep -v 127.0.0.1
```

**Windows:**
```bash
ipconfig | findstr IPv4
```

---

## 🗄️ Database Schema

The backend expects these Supabase tables:

### profiles
```sql
- id (uuid, primary key)
- email (text, unique)
- full_name (text)
- role (text) -- 'admin' or 'employee'
- phone_number (text, nullable)
- department_id (uuid, nullable, foreign key)
- profile_picture_url (text, nullable)
- face_embedding_url (text, nullable)
- is_active (boolean, default true)
- created_at (timestamp)
- updated_at (timestamp)
```

### attendance
```sql
- id (uuid, primary key)
- profile_id (uuid, foreign key → profiles)
- check_in (timestamp)
- check_out (timestamp, nullable)
- status (text) -- 'present', 'absent', 'late', 'half_day'
- check_in_gps (jsonb, nullable)
- check_out_gps (jsonb, nullable)
- is_wfh (boolean, default false)
- verification_method (text, nullable)
- check_in_photo_url (text, nullable)
- check_out_photo_url (text, nullable)
- face_match_confidence (float, nullable)
- device_id (text, nullable)
- notes (text, nullable)
- created_at (timestamp)
- updated_at (timestamp)
```

### leaves
```sql
- id (uuid, primary key)
- profile_id (uuid, foreign key → profiles)
- leave_type (text) -- 'sick', 'casual', 'earned', etc.
- start_date (date)
- end_date (date)
- status (text) -- 'pending', 'approved', 'rejected'
- reason (text)
- attachment_url (text, nullable)
- rejection_reason (text, nullable)
- approved_by (uuid, nullable, foreign key → profiles)
- approved_at (timestamp, nullable)
- created_at (timestamp)
- updated_at (timestamp)
```

### departments
```sql
- id (uuid, primary key)
- name (text, unique)
- description (text, nullable)
- manager_id (uuid, nullable, foreign key → profiles)
- created_at (timestamp)
- updated_at (timestamp)
```

### face_embeddings
```sql
- id (uuid, primary key)
- profile_id (uuid, foreign key → profiles)
- embedding (float[], array of face embedding values)
- photo_url (text)
- is_primary (boolean, default false)
- quality_score (float, nullable)
- created_at (timestamp)
```

---

## 🚀 Production Deployment

### Using Docker

```dockerfile
# Dockerfile
FROM python:3.10-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

```bash
# Build and run
docker build -t attendance-api .
docker run -p 8000:8000 --env-file .env attendance-api
```

### Using Railway/Render/Heroku

1. Push code to GitHub
2. Connect repository to platform
3. Set environment variables in platform dashboard
4. Deploy automatically

### Environment Variables for Production

```env
SUPABASE_URL=your_production_supabase_url
SUPABASE_SERVICE_KEY=your_service_key
SECRET_KEY=strong_random_secret_key
DEBUG=False
ENVIRONMENT=production
```

---

## 🔒 Security Features

- ✅ CORS middleware configured
- ✅ Input validation with Pydantic
- ✅ SQL injection protection (Supabase client)
- ✅ Face recognition for biometric auth
- ✅ Liveness detection
- ✅ Device binding support
- ✅ Mock location detection

---

## 📊 Monitoring & Logs

### View Logs
```bash
# In development
uvicorn app.main:app --reload --log-level debug

# In production
uvicorn app.main:app --log-level info
```

### Health Check
```bash
curl http://localhost:8000/health
```

---

## 🐛 Troubleshooting

### Issue: ModuleNotFoundError

**Solution:**
```bash
# Make sure you're in the correct directory
cd fastapi-backend

# Activate virtual environment
source venv/bin/activate  # macOS/Linux
venv\Scripts\activate  # Windows

# Reinstall dependencies
pip install -r requirements.txt
```

### Issue: Cannot connect to Supabase

**Solution:**
- Check `.env` file has correct credentials
- Verify Supabase project is active
- Check internet connection
- Verify firewall isn't blocking connection

### Issue: Face recognition not working

**Solution:**
```bash
# Install system dependencies (macOS)
brew install cmake

# Or on Ubuntu
sudo apt-get install cmake build-essential

# Reinstall dlib and face-recognition
pip uninstall dlib face-recognition
pip install dlib face-recognition
```

### Issue: Port 8000 already in use

**Solution:**
```bash
# Kill process using port 8000
lsof -ti:8000 | xargs kill -9

# Or use different port
uvicorn app.main:app --port 8001
```

---

## 📝 Development Tips

### Auto-reload on Code Changes
```bash
uvicorn app.main:app --reload
```

### Enable Debug Mode
```python
# In main.py
app = FastAPI(debug=True)
```

### Test Individual Endpoints
```bash
# Use Swagger UI at http://localhost:8000/docs
# Click "Try it out" on any endpoint
```

---

## ✅ Verification Checklist

- [ ] Python 3.10+ installed
- [ ] Virtual environment created
- [ ] Dependencies installed
- [ ] .env file configured
- [ ] Supabase connection working
- [ ] Server starts without errors
- [ ] Swagger UI accessible at /docs
- [ ] Test endpoints respond correctly
- [ ] Flutter app baseUrl updated
- [ ] Both apps on same network (for physical device)

---

## 🎉 You're All Set!

Your FastAPI backend is now:
- ✅ Running locally
- ✅ Connected to Supabase
- ✅ Serving all API endpoints
- ✅ Ready for Flutter app integration

**Next Steps:**
1. Keep backend running (`uvicorn app.main:app --reload`)
2. Update Flutter app baseUrl
3. Run Flutter app (`flutter run`)
4. Test all features end-to-end!

---

## 📚 Additional Resources

- **FastAPI Docs**: https://fastapi.tiangolo.com/
- **Supabase Docs**: https://supabase.com/docs
- **Python Face Recognition**: https://github.com/ageitgey/face_recognition

---

**Backend is production-ready! Happy coding! 🚀**
