-- ============================================
-- TEMPORARY FIX: Disable RLS to allow logins
-- Run this in Supabase SQL Editor
-- ============================================

-- Drop all existing policies causing infinite recursion
DROP POLICY IF EXISTS "Users can read own profile" ON profiles;
DROP POLICY IF EXISTS "Users can read company profiles" ON profiles;
DROP POLICY IF EXISTS "Service role full access profiles" ON profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
DROP POLICY IF EXISTS "Admins can create profiles" ON profiles;

-- Disable RLS temporarily
ALTER TABLE profiles DISABLE ROW LEVEL SECURITY;
ALTER TABLE companies DISABLE ROW LEVEL SECURITY;
ALTER TABLE departments DISABLE ROW LEVEL SECURITY;

-- Verify RLS is disabled
SELECT 
  schemaname,
  tablename,
  CASE 
    WHEN rowsecurity THEN '🔒 RLS ENABLED'
    ELSE '✅ RLS DISABLED'
  END as rls_status
FROM pg_tables
WHERE schemaname = 'public'
AND tablename IN ('profiles', 'companies', 'departments')
ORDER BY tablename;

-- Success message
DO $$
BEGIN
  RAISE NOTICE '✅ RLS disabled for profiles, companies, and departments';
  RAISE NOTICE '⚠️  This is temporary - reenable RLS with proper policies for production';
  RAISE NOTICE 'Now test: python test_all_logins.py';
END $$;
