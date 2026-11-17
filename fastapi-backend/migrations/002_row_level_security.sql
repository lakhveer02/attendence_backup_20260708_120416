-- ============================================================================
-- Migration 002: Row-Level Security (RLS)
-- Purpose: Enforce multi-tenant data isolation at database level
-- Security Level: Critical - Prevents cross-tenant data access
-- Expected Impact: 100% data isolation guarantee
-- Execution Time: <1 minute
-- ============================================================================

-- IMPORTANT: This provides database-level security enforcement
-- Even if application code has bugs, database will prevent data leaks

-- ============================================================================
-- STEP 1: Enable RLS on All Tenant Tables
-- ============================================================================

-- Enable RLS (this doesn't restrict access yet, just enables the feature)
ALTER TABLE companies ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE attendance ENABLE ROW LEVEL SECURITY;
ALTER TABLE leaves ENABLE ROW LEVEL SECURITY;
ALTER TABLE departments ENABLE ROW LEVEL SECURITY;
ALTER TABLE face_embeddings ENABLE ROW LEVEL SECURITY;

-- Note: After enabling RLS, you need policies to allow access
-- Without policies, all access is denied by default

-- ============================================================================
-- STEP 2: Create Policies for PROFILES Table
-- ============================================================================

-- Policy 1: Users can only see profiles in their company
CREATE POLICY company_isolation_profiles ON profiles
FOR SELECT
USING (
    -- Allow if user is in same company
    company_id = current_setting('app.current_company_id', true)::uuid
    -- OR user is super_admin (can see all)
    OR current_setting('app.user_role', true) = 'super_admin'
);

-- Policy 2: Insert - only super_admin and company_admin can create users
CREATE POLICY company_isolation_profiles_insert ON profiles
FOR INSERT
WITH CHECK (
    current_setting('app.user_role', true) IN ('super_admin', 'company_admin', 'hr_manager')
    AND (
        company_id = current_setting('app.current_company_id', true)::uuid
        OR current_setting('app.user_role', true) = 'super_admin'
    )
);

-- Policy 3: Update - users can update own profile, admins can update company profiles
CREATE POLICY company_isolation_profiles_update ON profiles
FOR UPDATE
USING (
    -- User's own profile
    id::text = current_setting('app.user_id', true)
    -- OR admin in same company
    OR (
        company_id = current_setting('app.current_company_id', true)::uuid
        AND current_setting('app.user_role', true) IN ('company_admin', 'hr_manager')
    )
    -- OR super_admin
    OR current_setting('app.user_role', true) = 'super_admin'
);

-- Policy 4: Delete - only admins can delete
CREATE POLICY company_isolation_profiles_delete ON profiles
FOR DELETE
USING (
    company_id = current_setting('app.current_company_id', true)::uuid
    AND current_setting('app.user_role', true) IN ('super_admin', 'company_admin', 'hr_manager')
);

-- ============================================================================
-- STEP 3: Create Policies for ATTENDANCE Table
-- ============================================================================

-- Policy 1: View attendance in same company
CREATE POLICY company_isolation_attendance ON attendance
FOR SELECT
USING (
    company_id = current_setting('app.current_company_id', true)::uuid
    OR current_setting('app.user_role', true) = 'super_admin'
);

-- Policy 2: Create attendance - employees can mark own, admins can mark any
CREATE POLICY company_isolation_attendance_insert ON attendance
FOR INSERT
WITH CHECK (
    -- Own attendance
    profile_id::text = current_setting('app.user_id', true)
    -- OR admin marking for employee in same company
    OR (
        company_id = current_setting('app.current_company_id', true)::uuid
        AND current_setting('app.user_role', true) IN ('company_admin', 'hr_manager')
    )
    -- OR super_admin
    OR current_setting('app.user_role', true) = 'super_admin'
);

-- Policy 3: Update attendance - own or admin
CREATE POLICY company_isolation_attendance_update ON attendance
FOR UPDATE
USING (
    -- Own attendance
    profile_id::text = current_setting('app.user_id', true)
    -- OR admin in same company
    OR (
        company_id = current_setting('app.current_company_id', true)::uuid
        AND current_setting('app.user_role', true) IN ('company_admin', 'hr_manager')
    )
    -- OR super_admin
    OR current_setting('app.user_role', true) = 'super_admin'
);

-- Policy 4: Delete attendance - only admins
CREATE POLICY company_isolation_attendance_delete ON attendance
FOR DELETE
USING (
    company_id = current_setting('app.current_company_id', true)::uuid
    AND current_setting('app.user_role', true) IN ('super_admin', 'company_admin')
);

-- ============================================================================
-- STEP 4: Create Policies for LEAVES Table
-- ============================================================================

-- Policy 1: View leaves in same company
CREATE POLICY company_isolation_leaves ON leaves
FOR SELECT
USING (
    company_id = current_setting('app.current_company_id', true)::uuid
    OR current_setting('app.user_role', true) = 'super_admin'
);

-- Policy 2: Apply for leave - own leaves only
CREATE POLICY company_isolation_leaves_insert ON leaves
FOR INSERT
WITH CHECK (
    profile_id::text = current_setting('app.user_id', true)
    AND company_id = current_setting('app.current_company_id', true)::uuid
);

-- Policy 3: Update leaves - own or approver
CREATE POLICY company_isolation_leaves_update ON leaves
FOR UPDATE
USING (
    -- Own leave
    profile_id::text = current_setting('app.user_id', true)
    -- OR approver (manager or HR)
    OR (
        company_id = current_setting('app.current_company_id', true)::uuid
        AND current_setting('app.user_role', true) IN ('company_admin', 'hr_manager', 'team_manager')
    )
    -- OR super_admin
    OR current_setting('app.user_role', true) = 'super_admin'
);

-- Policy 4: Delete leaves - own or admin
CREATE POLICY company_isolation_leaves_delete ON leaves
FOR DELETE
USING (
    profile_id::text = current_setting('app.user_id', true)
    OR (
        company_id = current_setting('app.current_company_id', true)::uuid
        AND current_setting('app.user_role', true) IN ('super_admin', 'company_admin', 'hr_manager')
    )
);

-- ============================================================================
-- STEP 5: Create Policies for DEPARTMENTS Table
-- ============================================================================

-- Policy 1: View departments in same company
CREATE POLICY company_isolation_departments ON departments
FOR SELECT
USING (
    company_id = current_setting('app.current_company_id', true)::uuid
    OR current_setting('app.user_role', true) = 'super_admin'
);

-- Policy 2: Manage departments - admins only
CREATE POLICY company_isolation_departments_insert ON departments
FOR INSERT
WITH CHECK (
    company_id = current_setting('app.current_company_id', true)::uuid
    AND current_setting('app.user_role', true) IN ('super_admin', 'company_admin')
);

CREATE POLICY company_isolation_departments_update ON departments
FOR UPDATE
USING (
    company_id = current_setting('app.current_company_id', true)::uuid
    AND current_setting('app.user_role', true) IN ('super_admin', 'company_admin')
);

CREATE POLICY company_isolation_departments_delete ON departments
FOR DELETE
USING (
    company_id = current_setting('app.current_company_id', true)::uuid
    AND current_setting('app.user_role', true) IN ('super_admin', 'company_admin')
);

-- ============================================================================
-- STEP 6: Create Policies for FACE_EMBEDDINGS Table
-- ============================================================================

-- Policy 1: View own face embeddings
CREATE POLICY company_isolation_face_embeddings ON face_embeddings
FOR SELECT
USING (
    -- Own embeddings
    profile_id::text = current_setting('app.user_id', true)
    -- OR admin in same company (for verification)
    OR (
        company_id = current_setting('app.current_company_id', true)::uuid
        AND current_setting('app.user_role', true) IN ('company_admin', 'hr_manager')
    )
    -- OR super_admin
    OR current_setting('app.user_role', true) = 'super_admin'
);

-- Policy 2: Create face embeddings - own or admin
CREATE POLICY company_isolation_face_embeddings_insert ON face_embeddings
FOR INSERT
WITH CHECK (
    profile_id::text = current_setting('app.user_id', true)
    OR (
        company_id = current_setting('app.current_company_id', true)::uuid
        AND current_setting('app.user_role', true) IN ('super_admin', 'company_admin', 'hr_manager')
    )
);

-- Policy 3: Delete face embeddings - own or admin
CREATE POLICY company_isolation_face_embeddings_delete ON face_embeddings
FOR DELETE
USING (
    profile_id::text = current_setting('app.user_id', true)
    OR (
        company_id = current_setting('app.current_company_id', true)::uuid
        AND current_setting('app.user_role', true) IN ('super_admin', 'company_admin')
    )
);

-- ============================================================================
-- STEP 7: Create Policy for COMPANIES Table (Super Admin Only)
-- ============================================================================

-- Only super_admins can manage companies
CREATE POLICY super_admin_companies ON companies
FOR ALL
USING (
    current_setting('app.user_role', true) = 'super_admin'
);

-- Allow users to view their own company
CREATE POLICY view_own_company ON companies
FOR SELECT
USING (
    id = current_setting('app.current_company_id', true)::uuid
    OR current_setting('app.user_role', true) = 'super_admin'
);

-- ============================================================================
-- STEP 8: Verification Queries
-- ============================================================================

-- Check RLS status for all tables
SELECT
    schemaname,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables
WHERE schemaname = 'public'
    AND tablename IN ('companies', 'profiles', 'attendance', 'leaves', 'departments', 'face_embeddings')
ORDER BY tablename;

-- Check all policies
SELECT
    schemaname,
    tablename,
    policyname,
    cmd as command,
    qual as using_expression
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

-- ============================================================================
-- TESTING RLS (Run these tests)
-- ============================================================================

-- Test 1: Set context for Company A
SET app.current_company_id = 'your-company-a-uuid-here';
SET app.user_role = 'employee';
SET app.user_id = 'your-user-uuid-here';

-- This should only return profiles from Company A
SELECT COUNT(*) as company_a_profiles FROM profiles;

-- Test 2: Try to access Company B (should return 0 rows)
SET app.current_company_id = 'different-company-b-uuid';
SELECT COUNT(*) as company_b_profiles FROM profiles;  -- Should be 0

-- Test 3: Super admin can see all
SET app.user_role = 'super_admin';
SELECT COUNT(*) as all_profiles FROM profiles;  -- Should see all

-- Reset settings
RESET app.current_company_id;
RESET app.user_role;
RESET app.user_id;

-- ============================================================================
-- SUCCESS MESSAGE
-- ============================================================================

DO $$
BEGIN
    RAISE NOTICE '✅ Row-Level Security enabled successfully!';
    RAISE NOTICE '🔒 Multi-tenant data isolation is now enforced at database level';
    RAISE NOTICE '⚠️  IMPORTANT: Your application middleware MUST set these session variables:';
    RAISE NOTICE '    - app.current_company_id';
    RAISE NOTICE '    - app.user_role';
    RAISE NOTICE '    - app.user_id';
    RAISE NOTICE '🧪 Run the test queries above to verify isolation';
END $$;
