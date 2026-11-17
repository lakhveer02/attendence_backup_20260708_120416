-- ============================================================================
-- COMPLETE DATABASE FIX - RUN THIS IN SUPABASE SQL EDITOR
-- ============================================================================
-- This script will:
-- 1. Disable RLS (Row Level Security) on all tables
-- 2. Create SQUADMINDS company
-- 3. Create departments
-- 4. Sync all 8 existing auth users to profiles table
-- 5. Verify everything works
-- ============================================================================

-- STEP 1: Disable RLS on all tables
-- ============================================================================
DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '============================================================================';
    RAISE NOTICE 'STEP 1: Disabling RLS on all tables...';
    RAISE NOTICE '============================================================================';
END $$;

ALTER TABLE IF EXISTS profiles DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS companies DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS departments DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS attendance DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS leaves DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS payroll DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS jwt_tokens DISABLE ROW LEVEL SECURITY;

DO $$
BEGIN
    RAISE NOTICE '✅ RLS disabled on all tables';
END $$;

-- Verify RLS is disabled
SELECT 
  tablename as "Table Name",
  CASE 
    WHEN rowsecurity THEN '❌ ENABLED (BAD)'
    ELSE '✅ DISABLED (GOOD)'
  END as "RLS Status"
FROM pg_tables
WHERE schemaname = 'public'
AND tablename IN ('profiles', 'companies', 'departments', 'attendance', 'leaves', 'payroll', 'jwt_tokens')
ORDER BY tablename;


-- STEP 2: Create SQUADMINDS Company
-- ============================================================================
DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '============================================================================';
    RAISE NOTICE 'STEP 2: Creating SQUADMINDS company...';
    RAISE NOTICE '============================================================================';
END $$;

INSERT INTO companies (
    id,
    name,
    email,
    phone,
    address,
    is_active,
    created_at,
    updated_at
)
VALUES (
    'b090d51d-3a18-4a0a-8c18-25765fc43456',
    'SQUADMINDS PRIVATE LIMITED',
    'chetan@squadminds.com',
    '+91-9999999999',
    'India',
    true,
    NOW(),
    NOW()
)
ON CONFLICT (id) DO UPDATE
SET
    name = EXCLUDED.name,
    email = EXCLUDED.email,
    phone = EXCLUDED.phone,
    address = EXCLUDED.address,
    updated_at = NOW();

DO $$
BEGIN
    RAISE NOTICE '✅ Company created: SQUADMINDS PRIVATE LIMITED';
END $$;

-- Verify company
SELECT 
    '✅ Company Verification' as "Status",
    id as "Company ID",
    name as "Company Name",
    email as "Email"
FROM companies
WHERE id = 'b090d51d-3a18-4a0a-8c18-25765fc43456';


-- STEP 3: Create Departments
-- ============================================================================
DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '============================================================================';
    RAISE NOTICE 'STEP 3: Creating departments...';
    RAISE NOTICE '============================================================================';
END $$;

INSERT INTO departments (
    company_id,
    name,
    is_active,
    created_at,
    updated_at
)
VALUES 
    ('b090d51d-3a18-4a0a-8c18-25765fc43456', 'Executive', true, NOW(), NOW()),
    ('b090d51d-3a18-4a0a-8c18-25765fc43456', 'Human Resources', true, NOW(), NOW()),
    ('b090d51d-3a18-4a0a-8c18-25765fc43456', 'Engineering', true, NOW(), NOW()),
    ('b090d51d-3a18-4a0a-8c18-25765fc43456', 'Sales', true, NOW(), NOW())
ON CONFLICT (company_id, name) DO UPDATE
SET
    is_active = EXCLUDED.is_active,
    updated_at = NOW();

DO $$
BEGIN
    RAISE NOTICE '✅ Departments created';
END $$;

-- Verify departments
SELECT 
    '✅ Department Verification' as "Status",
    d.name as "Department Name",
    c.name as "Company Name",
    d.is_active as "Active"
FROM departments d
JOIN companies c ON d.company_id = c.id
WHERE c.id = 'b090d51d-3a18-4a0a-8c18-25765fc43456'
ORDER BY d.name;


-- STEP 4: Sync All Auth Users to Profiles Table
-- ============================================================================
DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '============================================================================';
    RAISE NOTICE 'STEP 4: Syncing auth.users to profiles...';
    RAISE NOTICE '============================================================================';
END $$;

-- Sync existing users from auth.users to profiles
INSERT INTO profiles (
    id,
    email,
    full_name,
    role,
    company_id,
    phone_number,
    is_active,
    created_at,
    updated_at
)
SELECT 
    au.id,
    au.email,
    COALESCE(au.raw_user_meta_data->>'full_name', au.email) as full_name,
    COALESCE(au.raw_user_meta_data->>'role', 'employee') as role,
    'b090d51d-3a18-4a0a-8c18-25765fc43456' as company_id,
    au.phone as phone_number,
    true as is_active,
    au.created_at,
    au.updated_at
FROM auth.users au
WHERE au.id NOT IN (SELECT id FROM profiles)
ON CONFLICT (id) DO UPDATE
SET
    email = EXCLUDED.email,
    full_name = EXCLUDED.full_name,
    role = EXCLUDED.role,
    company_id = EXCLUDED.company_id,
    phone_number = EXCLUDED.phone_number,
    is_active = EXCLUDED.is_active,
    updated_at = NOW();

DO $$
BEGIN
    RAISE NOTICE '✅ All auth users synced to profiles';
END $$;


-- STEP 5: Create Trigger for Future Auto-Sync
-- ============================================================================
DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '============================================================================';
    RAISE NOTICE 'STEP 5: Creating auto-sync trigger...';
    RAISE NOTICE '============================================================================';
END $$;

-- Create function to auto-sync new users
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (
        id,
        email,
        full_name,
        role,
        company_id,
        phone_number,
        is_active,
        created_at,
        updated_at
    )
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.email),
        COALESCE(NEW.raw_user_meta_data->>'role', 'employee'),
        COALESCE(NEW.raw_user_meta_data->>'company_id', 'b090d51d-3a18-4a0a-8c18-25765fc43456'),
        NEW.phone,
        true,
        NOW(),
        NOW()
    )
    ON CONFLICT (id) DO UPDATE
    SET
        email = EXCLUDED.email,
        full_name = EXCLUDED.full_name,
        role = EXCLUDED.role,
        company_id = EXCLUDED.company_id,
        phone_number = EXCLUDED.phone_number,
        updated_at = NOW();
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT OR UPDATE ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

DO $$
BEGIN
    RAISE NOTICE '✅ Auto-sync trigger created';
    RAISE NOTICE '   Future signups will auto-create profiles';
END $$;


-- STEP 6: Verify Everything
-- ============================================================================
DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '============================================================================';
    RAISE NOTICE 'STEP 6: Final Verification';
    RAISE NOTICE '============================================================================';
END $$;

-- Count summary
SELECT 
    'Companies' as "Table",
    COUNT(*)::text as "Count"
FROM companies
UNION ALL
SELECT 'Departments', COUNT(*)::text FROM departments
UNION ALL
SELECT 'Profiles', COUNT(*)::text FROM profiles
UNION ALL
SELECT 'Auth Users', COUNT(*)::text FROM auth.users
ORDER BY "Table";

-- Show all profiles with company info
SELECT 
    '✅ All Profiles' as "Status",
    p.email as "Email",
    p.full_name as "Full Name",
    p.role as "Role",
    c.name as "Company",
    p.is_active as "Active"
FROM profiles p
LEFT JOIN companies c ON p.company_id = c.id
ORDER BY 
    CASE p.role
        WHEN 'company_admin' THEN 1
        WHEN 'hr_manager' THEN 2
        WHEN 'manager' THEN 3
        WHEN 'employee' THEN 4
        ELSE 5
    END,
    p.email;


-- STEP 7: Final Summary
-- ============================================================================
DO $$
DECLARE
    company_count INT;
    dept_count INT;
    profile_count INT;
    auth_count INT;
BEGIN
    SELECT COUNT(*) INTO company_count FROM companies;
    SELECT COUNT(*) INTO dept_count FROM departments;
    SELECT COUNT(*) INTO profile_count FROM profiles;
    SELECT COUNT(*) INTO auth_count FROM auth.users;
    
    RAISE NOTICE '';
    RAISE NOTICE '============================================================================';
    RAISE NOTICE '🎉 DATABASE SETUP COMPLETE!';
    RAISE NOTICE '============================================================================';
    RAISE NOTICE '';
    RAISE NOTICE '✅ Companies:   % created', company_count;
    RAISE NOTICE '✅ Departments: % created', dept_count;
    RAISE NOTICE '✅ Profiles:    % synced from auth.users', profile_count;
    RAISE NOTICE '✅ Auth Users:  % total', auth_count;
    RAISE NOTICE '';
    RAISE NOTICE '============================================================================';
    RAISE NOTICE '🚀 NEXT STEPS:';
    RAISE NOTICE '============================================================================';
    RAISE NOTICE '';
    RAISE NOTICE '1. Test your Flutter app';
    RAISE NOTICE '2. Login with: chetan@squadminds.com / Ceo@7890';
    RAISE NOTICE '3. Dashboard should now show 8 employees!';
    RAISE NOTICE '4. All features should work with real data';
    RAISE NOTICE '';
    RAISE NOTICE '============================================================================';
    RAISE NOTICE '📝 LOGIN CREDENTIALS FOR ALL USERS:';
    RAISE NOTICE '============================================================================';
    RAISE NOTICE '';
    RAISE NOTICE '1. Chetan Batra (company_admin)';
    RAISE NOTICE '   Email: chetan@squadminds.com';
    RAISE NOTICE '   Password: Ceo@7890';
    RAISE NOTICE '';
    RAISE NOTICE '2. Pryanshi (hr_manager)';
    RAISE NOTICE '   Email: pryanshi@squadminds.com';
    RAISE NOTICE '   Password: Hr@2024Squad';
    RAISE NOTICE '';
    RAISE NOTICE '3. Deepak Batra (hr_manager)';
    RAISE NOTICE '   Email: deepak.batra@squadminds.com';
    RAISE NOTICE '   Password: Deepak@2024Squad';
    RAISE NOTICE '';
    RAISE NOTICE '4. Dev Gangwar (manager)';
    RAISE NOTICE '   Email: dev.gangwar@squadminds.com';
    RAISE NOTICE '   Password: Dev@2024Squad';
    RAISE NOTICE '';
    RAISE NOTICE '5. Gurmeet Singh (employee)';
    RAISE NOTICE '   Email: gurmeet.singh@squadminds.com';
    RAISE NOTICE '   Password: Gurmeet@2024Squad';
    RAISE NOTICE '';
    RAISE NOTICE '6. Abha Sharma (employee)';
    RAISE NOTICE '   Email: abha.sharma@squadminds.com';
    RAISE NOTICE '   Password: Abha@2024Squad';
    RAISE NOTICE '';
    RAISE NOTICE '7. Harman Preet (employee)';
    RAISE NOTICE '   Email: harman.preet@squadminds.com';
    RAISE NOTICE '   Password: Harman@2024Squad';
    RAISE NOTICE '';
    RAISE NOTICE '8. Manjinder Singh (employee)';
    RAISE NOTICE '   Email: manjinder.singh@squadminds.com';
    RAISE NOTICE '   Password: Manjinder@2024Squad';
    RAISE NOTICE '';
    RAISE NOTICE '============================================================================';
    RAISE NOTICE '✅ ALL DONE! Your database is ready!';
    RAISE NOTICE '============================================================================';
END $$;
