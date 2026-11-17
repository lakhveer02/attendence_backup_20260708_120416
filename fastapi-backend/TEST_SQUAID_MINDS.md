# 🏢 SQUAID MINDS PRIVATE LIMITED - COMPLETE TEST SUITE

**Date:** June 24, 2026  
**Backend:** http://localhost:8000  
**Company:** Squaid Minds Private Limited  
**Status:** ✅ Users Created - Ready for Testing

---

## 🎯 QUICK START

All users have been created successfully in the database. Use the credentials below to test login in your Flutter app or via API.

### Company Information
- **Company Name:** Squaid Minds Private Limited
- **Company ID:** `102c4e0b-418c-4255-8338-8347cc244b78`
- **Status:** Active

---

## 📋 Test Execution Steps

### Step 1: Create Company Admin Account (Self-Service Signup)
```bash
curl -X POST http://localhost:8000/api/v1/auth/signup \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@squaidminds.com",
    "password": "SquaidAdmin@123",
    "full_name": "Squaid Company Admin",
    "role": "company_admin",
    "phone_number": "+91-9876543210",
    "create_company": true,
    "company_name": "Squaid Minds Private Limited",
    "workspace_slug": "squaid-minds"
  }' | python3 -m json.tool
```

**Expected Response:**
- ✅ Company created: Squaid Minds Private Limited
- ✅ Company admin created
- ✅ Access token received
- ✅ Refresh token received

---

### Step 2: Login as Company Admin
```bash
curl -X POST http://localhost:8000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@squaidminds.com",
    "password": "SquaidAdmin@123",
    "device_id": "test-admin-device"
  }' | python3 -m json.tool
```

Save the `access_token` for subsequent requests:
```bash
export ADMIN_TOKEN="<paste_access_token_here>"
```

---

### Step 3: Get Company ID
```bash
curl -X GET http://localhost:8000/api/v1/companies \
  | python3 -m json.tool | grep -A 5 "Squaid Minds"
```

Save the `company_id`:
```bash
export COMPANY_ID="<paste_company_id_here>"
```

---

### Step 4: Create HR Manager
```bash
curl -X POST http://localhost:8000/api/v1/auth/signup \
  -H "Content-Type: application/json" \
  -d "{
    \"email\": \"hr@squaidminds.com\",
    \"password\": \"SquaidHR@123\",
    \"full_name\": \"Squaid HR Manager\",
    \"role\": \"hr_manager\",
    \"phone_number\": \"+91-9876543211\",
    \"company_id\": \"$COMPANY_ID\"
  }" | python3 -m json.tool
```

**Expected Response:**
- ✅ HR Manager account created
- ✅ Linked to Squaid Minds Private Limited
- ✅ Tokens issued

---

### Step 5: Create Team Manager
```bash
curl -X POST http://localhost:8000/api/v1/auth/signup \
  -H "Content-Type: application/json" \
  -d "{
    \"email\": \"manager@squaidminds.com\",
    \"password\": \"SquaidManager@123\",
    \"full_name\": \"Squaid Team Manager\",
    \"role\": \"team_manager\",
    \"phone_number\": \"+91-9876543212\",
    \"company_id\": \"$COMPANY_ID\"
  }" | python3 -m json.tool
```

**Expected Response:**
- ✅ Team Manager account created
- ✅ Linked to Squaid Minds Private Limited
- ✅ Tokens issued

---

### Step 6: Create Employee 1
```bash
curl -X POST http://localhost:8000/api/v1/auth/signup \
  -H "Content-Type: application/json" \
  -d "{
    \"email\": \"employee1@squaidminds.com\",
    \"password\": \"SquaidEmp1@123\",
    \"full_name\": \"Rahul Kumar\",
    \"role\": \"employee\",
    \"phone_number\": \"+91-9876543213\",
    \"company_id\": \"$COMPANY_ID\"
  }" | python3 -m json.tool
```

**Expected Response:**
- ✅ Employee account created
- ✅ Linked to Squaid Minds Private Limited
- ✅ Tokens issued

---

### Step 7: Create Employee 2
```bash
curl -X POST http://localhost:8000/api/v1/auth/signup \
  -H "Content-Type: application/json" \
  -d "{
    \"email\": \"employee2@squaidminds.com\",
    \"password\": \"SquaidEmp2@123\",
    \"full_name\": \"Priya Sharma\",
    \"role\": \"employee\",
    \"phone_number\": \"+91-9876543214\",
    \"company_id\": \"$COMPANY_ID\"
  }" | python3 -m json.tool
```

**Expected Response:**
- ✅ Employee account created
- ✅ Linked to Squaid Minds Private Limited
- ✅ Tokens issued

---

### Step 8: Create Super Admin
```bash
curl -X POST http://localhost:8000/api/v1/auth/signup \
  -H "Content-Type: application/json" \
  -d '{
    "email": "superadmin@squaidminds.com",
    "password": "SuperAdmin@123",
    "full_name": "Super Administrator",
    "role": "super_admin",
    "phone_number": "+91-9999999999"
  }' | python3 -m json.tool
```

**Expected Response:**
- ✅ Super Admin account created
- ✅ System-wide access granted
- ✅ Tokens issued

---

## 🔐 USER CREDENTIALS SUMMARY

### 1️⃣ COMPANY ADMIN
```
Email:    admin@squaidminds.com
Password: SquaidAdmin@123
Role:     company_admin
Company:  Squaid Minds Private Limited
```

**Permissions:**
- ✅ Full company management
- ✅ Create/manage all users
- ✅ View all attendance
- ✅ Approve/reject leaves
- ✅ Access company reports
- ✅ Company settings

---

### 2️⃣ HR MANAGER
```
Email:    hr@squaidminds.com
Password: SquaidHR@123
Role:     hr_manager
Company:  Squaid Minds Private Limited
```

**Permissions:**
- ✅ Create/manage employees
- ✅ View all company attendance
- ✅ Approve/reject leave requests
- ✅ Access HR reports
- ✅ Manage employee profiles

---

### 3️⃣ TEAM MANAGER
```
Email:    manager@squaidminds.com
Password: SquaidManager@123
Role:     team_manager
Company:  Squaid Minds Private Limited
```

**Permissions:**
- ✅ View team attendance
- ✅ Approve team leave requests
- ✅ Manage team members
- ✅ Access team reports

---

### 4️⃣ EMPLOYEE 1
```
Email:    employee1@squaidminds.com
Password: SquaidEmp1@123
Role:     employee
Name:     Rahul Kumar
Company:  Squaid Minds Private Limited
```

**Permissions:**
- ✅ Mark own attendance
- ✅ View own attendance history
- ✅ Apply for leaves
- ✅ View own leave status
- ✅ Update own profile

---

### 5️⃣ EMPLOYEE 2
```
Email:    employee2@squaidminds.com
Password: SquaidEmp2@123
Role:     employee
Name:     Priya Sharma
Company:  Squaid Minds Private Limited
```

**Permissions:**
- ✅ Mark own attendance
- ✅ View own attendance history
- ✅ Apply for leaves
- ✅ View own leave status
- ✅ Update own profile

---

### 6️⃣ SUPER ADMIN
```
Email:    superadmin@squaidminds.com
Password: SuperAdmin@123
Role:     super_admin
Company:  System-wide access
```

**Permissions:**
- ✅ Manage all companies
- ✅ Create/delete companies
- ✅ Access all data across companies
- ✅ System configuration
- ✅ Create users with any role

---

## 🧪 LOGIN TESTING FOR ALL ROLES

### Test 1: Company Admin Login
```bash
curl -X POST http://localhost:8000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@squaidminds.com",
    "password": "SquaidAdmin@123",
    "device_id": "flutter-admin-device"
  }' | python3 -m json.tool
```

**Expected:**
- ✅ Login successful
- ✅ Role: company_admin
- ✅ Company: Squaid Minds Private Limited
- ✅ Access token with admin permissions

---

### Test 2: HR Manager Login
```bash
curl -X POST http://localhost:8000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "hr@squaidminds.com",
    "password": "SquaidHR@123",
    "device_id": "flutter-hr-device"
  }' | python3 -m json.tool
```

**Expected:**
- ✅ Login successful
- ✅ Role: hr_manager
- ✅ Company: Squaid Minds Private Limited
- ✅ Access token with HR permissions

---

### Test 3: Team Manager Login
```bash
curl -X POST http://localhost:8000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "manager@squaidminds.com",
    "password": "SquaidManager@123",
    "device_id": "flutter-manager-device"
  }' | python3 -m json.tool
```

**Expected:**
- ✅ Login successful
- ✅ Role: team_manager
- ✅ Company: Squaid Minds Private Limited
- ✅ Access token with manager permissions

---

### Test 4: Employee 1 Login
```bash
curl -X POST http://localhost:8000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "employee1@squaidminds.com",
    "password": "SquaidEmp1@123",
    "device_id": "flutter-employee1-device"
  }' | python3 -m json.tool
```

**Expected:**
- ✅ Login successful
- ✅ Role: employee
- ✅ Name: Rahul Kumar
- ✅ Company: Squaid Minds Private Limited
- ✅ Access token with employee permissions

---

### Test 5: Employee 2 Login
```bash
curl -X POST http://localhost:8000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "employee2@squaidminds.com",
    "password": "SquaidEmp2@123",
    "device_id": "flutter-employee2-device"
  }' | python3 -m json.tool
```

**Expected:**
- ✅ Login successful
- ✅ Role: employee
- ✅ Name: Priya Sharma
- ✅ Company: Squaid Minds Private Limited
- ✅ Access token with employee permissions

---

### Test 6: Super Admin Login
```bash
curl -X POST http://localhost:8000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "superadmin@squaidminds.com",
    "password": "SuperAdmin@123",
    "device_id": "flutter-superadmin-device"
  }' | python3 -m json.tool
```

**Expected:**
- ✅ Login successful
- ✅ Role: super_admin
- ✅ System-wide access
- ✅ Access token with super admin permissions

---

## 📱 FLUTTER APP TESTING

### Step 1: Update API Configuration
Edit `lib/core/constants/app_constants.dart`:

```dart
// For iOS Simulator / macOS
static const String fastApiBaseUrl = 'http://localhost:8000';

// For Android Emulator
static const String fastApiBaseUrl = 'http://10.0.2.2:8000';
```

### Step 2: Run Flutter App
```bash
cd /Users/squad-mac/Desktop/Flutter/attendence
flutter run
```

### Step 3: Test Each Role Login

1. **Company Admin:** admin@squaidminds.com / SquaidAdmin@123
2. **HR Manager:** hr@squaidminds.com / SquaidHR@123
3. **Team Manager:** manager@squaidminds.com / SquaidManager@123
4. **Employee 1:** employee1@squaidminds.com / SquaidEmp1@123
5. **Employee 2:** employee2@squaidminds.com / SquaidEmp2@123
6. **Super Admin:** superadmin@squaidminds.com / SuperAdmin@123

---

## ✅ VERIFICATION CHECKLIST

### Backend Setup
- [ ] Backend server running on port 8000
- [ ] Database connected to Supabase
- [ ] Company "Squaid Minds Private Limited" created
- [ ] All 6 users created successfully
- [ ] Each user can login successfully
- [ ] JWT tokens generated with correct permissions

### User Accounts
- [ ] Company Admin login works
- [ ] HR Manager login works
- [ ] Team Manager login works
- [ ] Employee 1 (Rahul) login works
- [ ] Employee 2 (Priya) login works
- [ ] Super Admin login works

### Frontend Testing
- [ ] Flutter app runs without errors
- [ ] Login screen displays correctly
- [ ] Company Admin sees admin dashboard
- [ ] HR Manager sees HR dashboard
- [ ] Team Manager sees manager dashboard
- [ ] Employees see employee home screen
- [ ] Super Admin sees super admin dashboard
- [ ] Attendance features work
- [ ] Leave application works

---

## 🎉 SUCCESS CRITERIA

All 6 users for **Squaid Minds Private Limited** should be able to:

✅ Sign up successfully  
✅ Login with correct credentials  
✅ Receive proper JWT tokens  
✅ Access role-specific dashboards  
✅ Perform role-specific actions  

---

**Document Version:** 1.0  
**Company:** Squaid Minds Private Limited  
**Last Updated:** June 24, 2026  
**Status:** 🟢 Ready for Testing
