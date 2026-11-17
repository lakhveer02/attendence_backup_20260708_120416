-- ============================================
-- ENABLE RLS AFTER DATA IS INSERTED
-- Run this AFTER you've created all your data
-- ============================================

-- Drop any existing policies first
DROP POLICY IF EXISTS "Users can read own profile" ON profiles;
DROP POLICY IF EXISTS "Users can read company profiles" ON profiles;
DROP POLICY IF EXISTS "Service role full access profiles" ON profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
DROP POLICY IF EXISTS "Admins can create profiles" ON profiles;
DROP POLICY IF EXISTS "Users can read own company" ON companies;
DROP POLICY IF EXISTS "Service role full access companies" ON companies;
DROP POLICY IF EXISTS "Admins can update own company" ON companies;
DROP POLICY IF EXISTS "Users can read company departments" ON departments;
DROP POLICY IF EXISTS "Service role full access departments" ON departments;

-- ============================================
-- ENABLE RLS ON TABLES
-- ============================================

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE companies ENABLE ROW LEVEL SECURITY;
ALTER TABLE departments ENABLE ROW LEVEL SECURITY;

-- ============================================
-- PROFILES TABLE POLICIES
-- ============================================

-- Policy 1: Users can read their own profile
CREATE POLICY "Users can read own profile"
ON profiles
FOR SELECT
USING (auth.uid() = id);

-- Policy 2: Users can read all profiles in their company
-- BUG FIX: Use JWT metadata to avoid recursive query
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

-- Policy 4: Service role and admins can create profiles
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

-- BUG FIX: Use JWT metadata to avoid recursive profile query
CREATE POLICY "Users can read own company"
ON companies
FOR SELECT
USING (
  id = COALESCE(
    (auth.jwt() ->> 'company_id')::uuid,
    (SELECT raw_app_meta_data->>'company_id' FROM auth.users WHERE id = auth.uid())::uuid
  )
);

-- BUG FIX: Use JWT metadata
CREATE POLICY "Admins can update own company"
ON companies
FOR UPDATE
USING (
  id = COALESCE(
    (auth.jwt() ->> 'company_id')::uuid,
    (SELECT raw_app_meta_data->>'company_id' FROM auth.users WHERE id = auth.uid())::uuid
  )
  AND (
    auth.role() = 'service_role'
    OR
    (auth.jwt() ->> 'role') IN ('company_admin', 'super_admin')
  )
);

CREATE POLICY "Service role full access companies"
ON companies
FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

-- ============================================
-- DEPARTMENTS TABLE POLICIES
-- ============================================

-- BUG FIX: Use JWT metadata
CREATE POLICY "Users can read company departments"
ON departments
FOR SELECT
USING (
  company_id = COALESCE(
    (auth.jwt() ->> 'company_id')::uuid,
    (SELECT raw_app_meta_data->>'company_id' FROM auth.users WHERE id = auth.uid())::uuid
  )
);

CREATE POLICY "Service role full access departments"
ON departments
FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

-- ============================================
-- VERIFICATION
-- ============================================

DO $$
BEGIN
    RAISE NOTICE '============================================';
    RAISE NOTICE '✅ RLS ENABLED SUCCESSFULLY!';
    RAISE NOTICE '============================================';
    RAISE NOTICE '';
    RAISE NOTICE '🔒 Security Status:';
    RAISE NOTICE '  • profiles: RLS enabled';
    RAISE NOTICE '  • companies: RLS enabled';
    RAISE NOTICE '  • departments: RLS enabled';
    RAISE NOTICE '';
    RAISE NOTICE '🐛 Bug Fixes Applied:';
    RAISE NOTICE '  • No more infinite recursion';
    RAISE NOTICE '  • JWT metadata used for company_id';
    RAISE NOTICE '  • Multi-tenant isolation active';
    RAISE NOTICE '';
END $$;

-- Show RLS status
SELECT
  tablename,
  CASE 
    WHEN rowsecurity THEN '✅ RLS Enabled'
    ELSE '❌ RLS Disabled'
  END as status
FROM pg_tables
WHERE schemaname = 'public'
AND tablename IN ('profiles', 'companies', 'departments')
ORDER BY tablename;

-- Show policies
SELECT
  tablename,
  policyname,
  CASE cmd
    WHEN 'r' THEN 'SELECT'
    WHEN 'a' THEN 'INSERT'
    WHEN 'w' THEN 'UPDATE'
    WHEN 'd' THEN 'DELETE'
    WHEN '*' THEN 'ALL'
  END as operation
FROM pg_policies
WHERE schemaname = 'public'
AND tablename IN ('profiles', 'companies', 'departments')
ORDER BY tablename, policyname;
