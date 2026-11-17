-- ============================================
-- FIX ROW LEVEL SECURITY POLICIES
-- Run this SQL in Supabase SQL Editor
-- 
-- BUG FIX: Resolved infinite recursion in RLS policies
-- Solution: Use JWT metadata (auth.jwt() ->> 'company_id')
-- instead of recursive SELECT from profiles table
-- ============================================

-- First, drop any existing conflicting policies
DROP POLICY IF EXISTS "Users can read own profile" ON profiles;
DROP POLICY IF EXISTS "Users can read company profiles" ON profiles;
DROP POLICY IF EXISTS "Service role full access" ON profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
DROP POLICY IF EXISTS "Admins can create profiles" ON profiles;
DROP POLICY IF EXISTS "Users can read own company" ON companies;
DROP POLICY IF EXISTS "Service role full access" ON companies;
DROP POLICY IF EXISTS "Admins can update own company" ON companies;
DROP POLICY IF EXISTS "Users can read company departments" ON departments;
DROP POLICY IF EXISTS "Service role full access" ON departments;

-- ============================================
-- PROFILES TABLE POLICIES
-- ============================================

-- Enable RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Policy 1: Users can read their own profile
CREATE POLICY "Users can read own profile"
ON profiles
FOR SELECT
USING (auth.uid() = id);

-- Policy 2: Users can read all profiles in their company
-- FIX: Use JWT metadata to avoid recursive profile query
CREATE POLICY "Users can read company profiles"
ON profiles
FOR SELECT
USING (
  company_id = COALESCE(
    (auth.jwt() ->> 'company_id')::uuid,
    (SELECT raw_app_meta_data->>'company_id' FROM auth.users WHERE id = auth.uid())::uuid
  )
);

-- Policy 3: Users can update their own profile
CREATE POLICY "Users can update own profile"
ON profiles
FOR UPDATE
USING (auth.uid() = id);

-- Policy 4: Admins can insert profiles in their company
-- Allow service role and authenticated users with admin roles
CREATE POLICY "Admins can create profiles"
ON profiles
FOR INSERT
WITH CHECK (
  auth.role() = 'service_role'
  OR
  (auth.jwt() ->> 'role') IN ('company_admin', 'super_admin', 'hr_manager')
);

-- Policy 5: Service role has full access (backend operations)
CREATE POLICY "Service role full access profiles"
ON profiles
FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

-- ============================================
-- COMPANIES TABLE POLICIES
-- ============================================

ALTER TABLE companies ENABLE ROW LEVEL SECURITY;

-- Users can read their own company
-- FIX: Use JWT metadata to avoid recursive profile query
CREATE POLICY "Users can read own company"
ON companies
FOR SELECT
USING (
  id = COALESCE(
    (auth.jwt() ->> 'company_id')::uuid,
    (SELECT raw_app_meta_data->>'company_id' FROM auth.users WHERE id = auth.uid())::uuid
  )
);

-- Admins can update their company
-- FIX: Use JWT metadata to avoid recursive profile query
CREATE POLICY "Admins can update own company"
ON companies
FOR UPDATE
USING (
  id = COALESCE(
    (auth.jwt() ->> 'company_id')::uuid,
    (SELECT raw_app_meta_data->>'company_id' FROM auth.users WHERE id = auth.uid())::uuid
  )
  AND auth.uid() IN (
    SELECT id FROM profiles 
    WHERE company_id = COALESCE(
      (auth.jwt() ->> 'company_id')::uuid,
      (SELECT raw_app_meta_data->>'company_id' FROM auth.users WHERE id = auth.uid())::uuid
    )
    AND role IN ('company_admin', 'super_admin')
  )
);

-- Service role has full access
CREATE POLICY "Service role full access companies"
ON companies
FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

-- ============================================
-- DEPARTMENTS TABLE POLICIES
-- ============================================

ALTER TABLE departments ENABLE ROW LEVEL SECURITY;

-- Users can read departments in their company
-- FIX: Use JWT metadata to avoid recursive profile query
CREATE POLICY "Users can read company departments"
ON departments
FOR SELECT
USING (
  company_id = COALESCE(
    (auth.jwt() ->> 'company_id')::uuid,
    (SELECT raw_app_meta_data->>'company_id' FROM auth.users WHERE id = auth.uid())::uuid
  )
);

-- Service role has full access
CREATE POLICY "Service role full access departments"
ON departments
FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

-- ============================================
-- VERIFICATION QUERY
-- ============================================

-- Check that policies were created
SELECT
  schemaname,
  tablename,
  policyname,
  permissive,
  cmd,
  CASE
    WHEN tablename = 'profiles' THEN '✅ Profiles'
    WHEN tablename = 'companies' THEN '✅ Companies'
    WHEN tablename = 'departments' THEN '✅ Departments'
  END as status
FROM pg_policies
WHERE schemaname = 'public'
AND tablename IN ('profiles', 'companies', 'departments')
ORDER BY tablename, policyname;

-- ============================================
-- SUCCESS MESSAGE
-- ============================================

DO $$
BEGIN
  RAISE NOTICE '✅ RLS Policies successfully created!';
  RAISE NOTICE 'Now test login with: python fix_dev_gangwar.py';
END $$;
