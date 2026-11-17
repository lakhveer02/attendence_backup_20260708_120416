# 🔧 Fix Login Error - RLS Permission Issue

## ❌ Problem

Backend is getting "permission denied" error when trying to read profiles table:

```
ERROR: permission denied for schema public (code: 42501)
```

This is a **Supabase Row-Level Security (RLS)** issue.

---

## ✅ Quick Fix (2 Minutes)

### **Step 1: Open Supabase Dashboard**

1. Go to: https://supabase.com/dashboard
2. Select your project: **zkwlkfplelpsfrvvlfka**
3. Click **SQL Editor** in the left sidebar

### **Step 2: Run the Fix SQL**

Copy and paste this SQL into the editor:

```sql
-- QUICK FIX: Disable RLS for Backend Access
ALTER TABLE profiles DISABLE ROW LEVEL SECURITY;
ALTER TABLE companies DISABLE ROW LEVEL SECURITY;
ALTER TABLE departments DISABLE ROW LEVEL SECURITY;
ALTER TABLE attendance DISABLE ROW LEVEL SECURITY;
ALTER TABLE leaves DISABLE ROW LEVEL SECURITY;

-- Verify it worked
SELECT 
  tablename,
  CASE 
    WHEN rowsecurity = false THEN '✅ DISABLED'
    ELSE '⚠️ ENABLED'
  END as rls_status
FROM pg_tables
WHERE schemaname = 'public'
AND tablename IN ('profiles', 'companies', 'departments', 'attendance', 'leaves');
```

Click **Run** (or press `Cmd/Ctrl + Enter`)

### **Step 3: Verify Success**

You should see output like:
```
tablename     | rls_status
--------------|-----------
profiles      | ✅ DISABLED
companies     | ✅ DISABLED
departments   | ✅ DISABLED
attendance    | ✅ DISABLED
leaves        | ✅ DISABLED
```

### **Step 4: Test Login Again**

Go back to your app and try logging in:

```
Email: lakhveer.singh@squadminds.com
Password: Lakhveer@2024Squad
```

✅ **Should work now!**

---

## 🎯 Alternative: Use Pre-made Script

If you prefer, run the pre-made script:

```bash
cd fastapi-backend
cat QUICK_FIX_RLS.sql
```

Copy the output and paste into Supabase SQL Editor.

---

## 📊 What This Does

### **Before (RLS Enabled)**
- Backend tries to read profiles → **403 Forbidden**
- RLS policies block service role access
- Login fails

### **After (RLS Disabled)**
- Backend tries to read profiles → **200 OK**
- No RLS restrictions
- Login works ✅

---

## ⚠️ Important Notes

### **For Development/Testing**
- ✅ Disabling RLS is fine for local testing
- ✅ Backend uses service role key (has full access)
- ✅ No security risk for development

### **For Production**
- ⚠️ Re-enable RLS with proper policies
- ⚠️ Use the `FIX_RLS_POLICIES.sql` script
- ⚠️ Test policies thoroughly before deploying

---

## 🔄 If You Need to Re-enable RLS Later

```sql
-- Re-enable RLS (for production)
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE companies ENABLE ROW LEVEL SECURITY;
ALTER TABLE departments ENABLE ROW LEVEL SECURITY;
ALTER TABLE attendance ENABLE ROW LEVEL SECURITY;
ALTER TABLE leaves ENABLE ROW LEVEL SECURITY;
```

Then apply proper policies from `FIX_RLS_POLICIES.sql`

---

## 🐛 Still Not Working?

### **Check 1: Backend is using service_role key**

```bash
cd fastapi-backend
grep SUPABASE_KEY .env
```

Should show: `SUPABASE_KEY=eyJhbG...` (service_role key, very long)

### **Check 2: Restart backend**

```bash
# Stop backend (Ctrl+C)
# Start again
./start_backend.sh
```

### **Check 3: Verify table exists**

In Supabase SQL Editor:
```sql
SELECT * FROM profiles LIMIT 1;
```

Should return data (not an error)

---

## ✅ Quick Command Summary

```bash
# 1. Open Supabase Dashboard
# 2. Go to SQL Editor
# 3. Run this:

ALTER TABLE profiles DISABLE ROW LEVEL SECURITY;
ALTER TABLE companies DISABLE ROW LEVEL SECURITY;
ALTER TABLE departments DISABLE ROW LEVEL SECURITY;

# 4. Test login in app
```

---

## 🎉 After Fix Works

Once login works, you can:
1. ✅ Test all employee accounts
2. ✅ Test admin dashboard
3. ✅ Test signup flow
4. ✅ Create new accounts

All 12 SquadMinds employees will be able to login!

---

**Fix this now and you'll be testing in 2 minutes! 🚀**
