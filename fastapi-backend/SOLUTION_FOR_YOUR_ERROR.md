# 🔧 Solution for "relation 'profiles' does not exist" Error

## ❌ Your Error:
```
Error: Failed to run sql query: ERROR: 42P01: relation "profiles" does not exist
```

## ✅ The Fix (2 Simple Steps):

### Step 1: Create Tables (Without RLS)

**File to run**: `RUN_THIS_FIRST.sql`

1. Open Supabase SQL Editor
2. Copy entire content of `RUN_THIS_FIRST.sql`
3. Paste and click "Run"
4. Wait for success message

This creates all 7 tables WITHOUT RLS (no security yet, but no errors!)

### Step 2: Insert Your Data

Now run Python script to create SQUADMINDS company:

```bash
cd fastapi-backend
python create_squadminds_company.py
```

This will:
- ✅ Create SQUADMINDS company
- ✅ Create 11 employees (including Dev Gangwar as 'manager')
- ✅ Set up organizational structure
- ✅ No RLS errors because RLS is disabled!

### Step 3 (Optional): Enable RLS

After data is inserted, if you want security:

**File to run**: `ENABLE_RLS_AFTER_DATA.sql`

1. Open Supabase SQL Editor
2. Copy entire content of `ENABLE_RLS_AFTER_DATA.sql`
3. Paste and click "Run"
4. RLS now enabled with bug fixes!

---

## 📁 Which Files to Use:

```
Order of Operations:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1️⃣  RUN_THIS_FIRST.sql
    └─ Creates tables WITHOUT RLS
    └─ No errors, works every time ✅

2️⃣  python create_squadminds_company.py  
    └─ Inserts all test data
    └─ Creates 11 employees with credentials

3️⃣  ENABLE_RLS_AFTER_DATA.sql (optional)
    └─ Enables security policies
    └─ Use in production, optional in development
```

---

## 🤔 Why This Works:

Your original error happened because:

1. You ran `FIX_RLS_POLICIES.sql` 
2. But tables didn't exist yet!
3. SQL tried to create policies on non-existent tables → ERROR

The solution:
1. Create tables FIRST (without RLS)
2. Insert data while RLS is off
3. Enable RLS later (optional)

---

## 🧪 Testing After Setup:

```bash
# 1. Test backend
cd fastapi-backend
uvicorn app.main:app --reload

# 2. Test login
python test_login_direct.py

# 3. Test check-in with dynamic geofencing
curl -X POST http://localhost:8000/api/v1/hrms/attendance/checkin \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "check_in_gps": {
      "latitude": 30.7046,
      "longitude": 76.7179
    },
    "verification_method": "biometric",
    "device_id": "test-1",
    "is_wfh": false
  }'
```

---

## 🎯 What's Fixed:

After running these scripts, all 3 bugs are fixed:

✅ **Bug #1**: RLS infinite recursion
   - Uses JWT metadata instead of recursive queries
   
✅ **Bug #2**: Hardcoded Mohali coordinates  
   - Dynamically queries company location from database
   
✅ **Bug #3**: Dev Gangwar's role
   - Changed from 'team_manager' to 'manager'

---

## 📊 File Reference:

| File | Purpose | When to Use |
|------|---------|-------------|
| `RUN_THIS_FIRST.sql` | Create tables | **Use this NOW!** |
| `create_squadminds_company.py` | Insert data | After tables exist |
| `ENABLE_RLS_AFTER_DATA.sql` | Enable security | Optional (for production) |
| `FIX_RLS_POLICIES.sql` | ❌ Don't use alone | Only after tables exist |
| `SETUP_DATABASE_COMPLETE.sql` | All-in-one | Alternative to step 1+3 |

---

## 🚨 Common Mistakes to Avoid:

❌ **DON'T** run `FIX_RLS_POLICIES.sql` first  
✅ **DO** run `RUN_THIS_FIRST.sql` first

❌ **DON'T** run `create_squadminds_company.py` before creating tables  
✅ **DO** create tables, then run Python script

❌ **DON'T** enable RLS before inserting data (in development)  
✅ **DO** insert data first, enable RLS later

---

## 💡 Development vs Production:

### Development (Recommended):
1. Run `RUN_THIS_FIRST.sql` (no RLS)
2. Run `create_squadminds_company.py`
3. Develop and test freely
4. Enable RLS later if needed

### Production (Secure):
1. Run `RUN_THIS_FIRST.sql`
2. Run `ENABLE_RLS_AFTER_DATA.sql` immediately
3. Insert data via service_role key
4. RLS protects all queries

---

## 📞 Still Getting Errors?

If you still see "relation does not exist":

1. **Check you're in the right database**
   - Supabase project URL correct?
   - Schema is 'public'?

2. **Check Supabase connection**
   ```bash
   # In .env file:
   SUPABASE_URL=https://your-project.supabase.co
   SUPABASE_SERVICE_KEY=your-service-role-key
   ```

3. **Drop and recreate everything**
   ```sql
   -- In Supabase SQL Editor:
   DROP SCHEMA public CASCADE;
   CREATE SCHEMA public;
   -- Then run RUN_THIS_FIRST.sql
   ```

---

## ✅ Success Checklist:

After running the scripts, verify:

- [ ] 7 tables created (companies, profiles, departments, attendance, leaves, payroll, jwt_tokens)
- [ ] Can run `python create_squadminds_company.py` without errors
- [ ] See 11 employees in SQUADMINDS_CREDENTIALS.txt
- [ ] Can login with any test credentials
- [ ] Check-in works with GPS validation

---

**Status**: Ready to fix your error!  
**Time**: ~5 minutes  
**Difficulty**: Copy-paste SQL ✅
