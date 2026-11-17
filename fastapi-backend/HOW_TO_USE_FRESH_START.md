# 🚀 How to Use FRESH_START.sql

## What This Does

`FRESH_START.sql` is a complete database reset that:

1. **Deletes ALL existing tables** (⚠️ destroys all data!)
2. **Creates 7 new tables** from scratch
3. **Adds all indexes** for performance
4. **Enables RLS** with all bug fixes applied
5. **Ready for data** immediately

## ⚠️ WARNING

This script **DELETES ALL DATA** in your database!

- All companies will be deleted
- All users will be deleted
- All attendance records will be deleted
- All everything will be GONE!

Only use this if you want a completely fresh start.

---

## 🎯 Step-by-Step Instructions

### Step 1: Backup (Optional but Recommended)

If you have any data you want to keep:

```bash
# Export from Supabase first (if needed)
```

### Step 2: Run the Script

1. Open **Supabase Dashboard**
2. Click **"SQL Editor"** in left sidebar
3. Click **"New Query"**
4. Copy entire content of `FRESH_START.sql`
5. Paste into SQL Editor
6. Click **"Run"** button (or press Cmd+Enter)

### Step 3: Wait for Completion

You'll see messages like:
```
✅ FRESH START COMPLETE!
```

And a table showing:
```
✅ Table          | Security      | Size
companies        | RLS Enabled   | 8192 bytes
profiles         | RLS Enabled   | 8192 bytes
departments      | RLS Enabled   | 8192 bytes
attendance       | No RLS        | 8192 bytes
...
```

### Step 4: Create Test Data

Now create SQUADMINDS company with 11 employees:

```bash
cd fastapi-backend
python create_squadminds_company.py
```

Output should show:
```
✅ Company created: SQUADMINDS PRIVATE LIMITED
✅ [1/12] Chantenbarta (company_admin) - Chief Executive Officer
✅ [2/12] Pryanshi (hr_manager) - HR Manager
...
✅ [4/12] Dev Gangwar (manager) - Team Manager  ← Fixed role!
...
```

### Step 5: Verify Success

Check tables have data:

```sql
-- Run in Supabase SQL Editor
SELECT COUNT(*) as companies FROM companies;
SELECT COUNT(*) as profiles FROM profiles;
SELECT name, role FROM profiles ORDER BY role;
```

Expected results:
- 1 company (SQUADMINDS)
- 12 profiles (1 CEO + 2 HR + 1 Manager + 8 Employees)

---

## 🐛 Bug Fixes Included

### ✅ Bug #1: RLS Infinite Recursion Fixed

**Before (Broken):**
```sql
-- This caused infinite loops
company_id IN (
  SELECT company_id FROM profiles WHERE id = auth.uid()
)
```

**After (Fixed):**
```sql
-- Reads directly from JWT token
company_id = COALESCE(
  (auth.jwt() ->> 'company_id')::uuid,
  ...
)
```

### ✅ Bug #2: Dynamic Geofencing Ready

Tables include columns for GPS-based geofencing:
- `companies.office_latitude`
- `companies.office_longitude`
- `companies.geofence_radius_meters`

Backend (`app/routes/hrms.py`) queries these dynamically.

### ✅ Bug #3: Manager Role Supported

Role constraint updated:
```sql
CHECK (role IN ('super_admin', 'company_admin', 'hr_manager', 'manager', 'employee'))
```

Now accepts `'manager'` (not `'team_manager'`)

---

## 📊 Tables Created

| # | Table | Description | RLS |
|---|-------|-------------|-----|
| 1 | `companies` | Organizations with office GPS | ✅ |
| 2 | `profiles` | Users with RBAC roles | ✅ |
| 3 | `departments` | Company departments | ✅ |
| 4 | `attendance` | Check-in/out with GPS | ❌ |
| 5 | `leaves` | Leave requests | ❌ |
| 6 | `payroll` | Salary records | ❌ |
| 7 | `jwt_tokens` | Session management | ❌ |

**Note**: RLS is enabled only on tables with multi-tenant isolation needs.

---

## 🧪 Testing After Fresh Start

### Test 1: Login

```bash
cd fastapi-backend
python test_login_direct.py
```

Use credentials:
```
Email: chantenbarta@squadminds.com
Password: Ceo@2024Squad
```

### Test 2: Check-In with Geofencing

```bash
# Start backend
uvicorn app.main:app --reload

# Test check-in
curl -X POST http://localhost:8000/api/v1/hrms/attendance/checkin \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "check_in_gps": {
      "latitude": 30.7046,
      "longitude": 76.7179
    },
    "verification_method": "biometric",
    "device_id": "test-device-1",
    "is_wfh": false
  }'
```

Should return:
```json
{
  "success": true,
  "message": "Check-in successful",
  "distance_from_office": 0.0,
  "company_name": "SQUADMINDS PRIVATE LIMITED"
}
```

### Test 3: Dev Gangwar Permissions

Login as Dev Gangwar and verify he can:
- ✅ Approve leave requests from his team
- ✅ View team attendance (8 developers)
- ✅ Assign tasks to team members

---

## 🔄 If Something Goes Wrong

### Issue 1: Script fails midway

```sql
-- Drop everything and try again
DROP SCHEMA public CASCADE;
CREATE SCHEMA public;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO public;

-- Then run FRESH_START.sql again
```

### Issue 2: RLS blocks inserts

Make sure you're using **service_role key** in `.env`:

```bash
SUPABASE_SERVICE_KEY=eyJ...your-service-role-key
```

Not the anon key!

### Issue 3: Company creation fails

Check auth.users table:
```sql
SELECT id, email FROM auth.users;
```

If empty, Supabase auth isn't working. Check API keys.

---

## 📁 Related Files

After running FRESH_START.sql, you can use:

- ✅ `create_squadminds_company.py` - Creates test data
- ✅ `app/routes/hrms.py` - Check-in with geofencing
- ✅ `test_login_direct.py` - Test authentication
- ❌ Don't use `FIX_RLS_POLICIES.sql` (already included)
- ❌ Don't use `CREATE_TABLES_SCHEMA.sql` (already included)

---

## ⏱️ Execution Time

- Script runs in: **~5 seconds**
- Python script: **~30 seconds**
- Total setup: **< 1 minute**

---

## ✅ Success Checklist

After running everything, verify:

- [ ] 7 tables exist in Supabase
- [ ] 3 tables have RLS enabled (profiles, companies, departments)
- [ ] 1 company exists (SQUADMINDS)
- [ ] 12 users exist (1 CEO, 2 HR, 1 Manager, 8 Employees)
- [ ] Dev Gangwar has role = 'manager'
- [ ] Can login with any test credential
- [ ] Check-in calculates distance dynamically
- [ ] No "relation does not exist" errors
- [ ] No "infinite recursion" errors

---

## 🎉 You're Done!

Database is now:
- ✅ Clean and fresh
- ✅ All bugs fixed
- ✅ Security enabled
- ✅ Test data loaded
- ✅ Ready for development

Start your backend:
```bash
cd fastapi-backend
uvicorn app.main:app --reload
```

And your Flutter app:
```bash
flutter run
```

---

**File**: `FRESH_START.sql`  
**Purpose**: Complete database reset with bug fixes  
**Status**: ✅ Production ready  
**Time**: ~5 seconds to run  
**Risk**: ⚠️ Deletes all data
