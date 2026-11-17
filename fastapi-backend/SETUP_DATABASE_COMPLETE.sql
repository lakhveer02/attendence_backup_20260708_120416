-- ============================================
-- SQUADMINDS HRMS - COMPLETE DATABASE SETUP
-- Run this script in Supabase SQL Editor
-- 
-- This script will:
-- 1. Create all tables and schema
-- 2. Apply Row-Level Security policies
-- 3. Verify setup
-- ============================================

-- ============================================
-- PART 1: CREATE SCHEMA
-- ============================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. COMPANIES TABLE
CREATE TABLE IF NOT EXISTS companies (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(200) NOT NULL,
    workspace_slug VARCHAR(100) UNIQUE,
    joining_token VARCHAR(8) UNIQUE,
    industry VARCHAR(100),
    status VARCHAR(50) DEFAULT 'active',
    timezone VARCHAR(50) DEFAULT 'UTC',
    office_latitude DECIMAL(10, 8),
    office_longitude DECIMAL(11, 8),
    geofence_radius_meters INTEGER DEFAULT 100,
    logo_url TEXT,
    settings JSONB DEFAULT '{}'::jsonb,
    subscription_plan VARCHAR(50) DEFAULT 'trial',
    subscription_status VARCHAR(50) DEFAULT 'active',
    max_employees INTEGER DEFAULT 50,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_companies_workspace_slug ON companies(workspace_slug);
CREATE INDEX IF NOT EXISTS idx_companies_status ON companies(status);

-- 2. PROFILES TABLE
CREATE TABLE IF NOT EXISTS profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    company_id UUID REFERENCES companies(id) ON DELETE CASCADE,
    workspace_id UUID REFERENCES companies(id) ON DELETE CASCADE,
    email VARCHAR(255) UNIQUE NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    phone_number VARCHAR(20),
    role VARCHAR(50) NOT NULL DEFAULT 'employee',
    employee_id VARCHAR(50),
    department_id UUID,
    department_name VARCHAR(255),
    designation VARCHAR(100),
    reporting_manager_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
    profile_picture_url TEXT,
    face_embedding_url TEXT,
    device_id VARCHAR(255),
    is_active BOOLEAN DEFAULT TRUE,
    is_first_login BOOLEAN DEFAULT TRUE,
    is_verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    last_login TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_profiles_company_id ON profiles(company_id);
CREATE INDEX IF NOT EXISTS idx_profiles_email ON profiles(email);
CREATE INDEX IF NOT EXISTS idx_profiles_role ON profiles(role);

ALTER TABLE profiles ADD CONSTRAINT IF NOT EXISTS check_role 
    CHECK (role IN ('super_admin', 'company_admin', 'hr_manager', 'manager', 'employee'));

-- 3. DEPARTMENTS TABLE
CREATE TABLE IF NOT EXISTS departments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    code VARCHAR(20),
    description TEXT,
    head_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(company_id, name)
);

CREATE INDEX IF NOT EXISTS idx_departments_company_id ON departments(company_id);

-- 4. ATTENDANCE TABLE
CREATE TABLE IF NOT EXISTS attendance (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    check_in TIMESTAMP NOT NULL,
    check_out TIMESTAMP,
    total_hours DECIMAL(5, 2),
    status VARCHAR(50) DEFAULT 'present',
    check_in_gps JSONB,
    check_out_gps JSONB,
    distance_from_office DECIMAL(10, 2),
    is_wfh BOOLEAN DEFAULT FALSE,
    verification_method VARCHAR(50),
    face_match_confidence DECIMAL(5, 2),
    device_id VARCHAR(255),
    device_model VARCHAR(100),
    device_os VARCHAR(50),
    notes TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_attendance_company_id ON attendance(company_id);
CREATE INDEX IF NOT EXISTS idx_attendance_profile_id ON attendance(profile_id);
CREATE INDEX IF NOT EXISTS idx_attendance_check_in ON attendance(check_in);

-- 5. LEAVES TABLE
CREATE TABLE IF NOT EXISTS leaves (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    leave_type VARCHAR(50) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    half_day BOOLEAN DEFAULT FALSE,
    total_days DECIMAL(4, 1),
    reason TEXT NOT NULL,
    status VARCHAR(50) DEFAULT 'pending',
    approved_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
    approved_at TIMESTAMP,
    rejection_reason TEXT,
    attachment_url TEXT,
    replacement_profile_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
    emergency_contact VARCHAR(100),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_leaves_company_id ON leaves(company_id);
CREATE INDEX IF NOT EXISTS idx_leaves_profile_id ON leaves(profile_id);
CREATE INDEX IF NOT EXISTS idx_leaves_status ON leaves(status);

-- 6. PAYROLL TABLE
CREATE TABLE IF NOT EXISTS payroll (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    month INTEGER NOT NULL,
    year INTEGER NOT NULL,
    basic_salary DECIMAL(10, 2) NOT NULL,
    hra DECIMAL(10, 2) DEFAULT 0,
    allowances DECIMAL(10, 2) DEFAULT 0,
    bonus DECIMAL(10, 2) DEFAULT 0,
    gross_salary DECIMAL(10, 2),
    deductions DECIMAL(10, 2) DEFAULT 0,
    pf DECIMAL(10, 2) DEFAULT 0,
    esi DECIMAL(10, 2) DEFAULT 0,
    tds DECIMAL(10, 2) DEFAULT 0,
    net_salary DECIMAL(10, 2) NOT NULL,
    present_days INTEGER,
    absent_days INTEGER,
    leave_days INTEGER,
    working_days INTEGER DEFAULT 22,
    overtime_hours DECIMAL(5, 2) DEFAULT 0,
    late_penalty DECIMAL(10, 2) DEFAULT 0,
    status VARCHAR(50) DEFAULT 'draft',
    paid_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(company_id, profile_id, month, year)
);

CREATE INDEX IF NOT EXISTS idx_payroll_company_id ON payroll(company_id);
CREATE INDEX IF NOT EXISTS idx_payroll_profile_id ON payroll(profile_id);

-- 7. JWT_TOKENS TABLE
CREATE TABLE IF NOT EXISTS jwt_tokens (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    token_id VARCHAR(255) UNIQUE NOT NULL,
    device_id VARCHAR(255) NOT NULL,
    device_name VARCHAR(255),
    is_valid BOOLEAN DEFAULT TRUE,
    issued_at TIMESTAMP NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    last_used_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_jwt_tokens_profile_id ON jwt_tokens(profile_id);
CREATE INDEX IF NOT EXISTS idx_jwt_tokens_token_id ON jwt_tokens(token_id);

-- ============================================
-- PART 2: APPLY RLS POLICIES (BUG FIX #1)
-- ============================================

-- Drop existing policies
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

-- PROFILES TABLE POLICIES
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

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

-- COMPANIES TABLE POLICIES
ALTER TABLE companies ENABLE ROW LEVEL SECURITY;

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
  AND auth.uid() IN (
    SELECT id FROM profiles 
    WHERE company_id = COALESCE(
      (auth.jwt() ->> 'company_id')::uuid,
      (SELECT raw_app_meta_data->>'company_id' FROM auth.users WHERE id = auth.uid())::uuid
    )
    AND role IN ('company_admin', 'super_admin')
  )
);

CREATE POLICY "Service role full access companies"
ON companies
FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

-- DEPARTMENTS TABLE POLICIES
ALTER TABLE departments ENABLE ROW LEVEL SECURITY;

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
-- PART 3: VERIFICATION
-- ============================================

DO $$
BEGIN
    RAISE NOTICE '============================================';
    RAISE NOTICE '✅ DATABASE SETUP COMPLETE!';
    RAISE NOTICE '============================================';
    RAISE NOTICE '';
    RAISE NOTICE '📋 Summary:';
    RAISE NOTICE '  • All tables created';
    RAISE NOTICE '  • RLS policies applied (with bug fixes)';
    RAISE NOTICE '  • Indexes created';
    RAISE NOTICE '  • Constraints enforced';
    RAISE NOTICE '';
    RAISE NOTICE '🎯 Next steps:';
    RAISE NOTICE '  1. Run: python create_squadminds_company.py';
    RAISE NOTICE '  2. Test login with credentials';
    RAISE NOTICE '  3. Test check-in with geofencing';
    RAISE NOTICE '';
END $$;

-- List created tables with RLS status
SELECT 
    tablename,
    CASE
        WHEN tablename = 'companies' THEN '✅ Companies (RLS enabled)'
        WHEN tablename = 'profiles' THEN '✅ Profiles (RLS enabled)'
        WHEN tablename = 'departments' THEN '✅ Departments (RLS enabled)'
        WHEN tablename = 'attendance' THEN '✅ Attendance'
        WHEN tablename = 'leaves' THEN '✅ Leaves'
        WHEN tablename = 'payroll' THEN '✅ Payroll'
        WHEN tablename = 'jwt_tokens' THEN '✅ JWT Tokens'
    END as status,
    pg_size_pretty(pg_total_relation_size('public.'||tablename)) as size
FROM pg_tables
WHERE schemaname = 'public'
AND tablename IN ('companies', 'profiles', 'departments', 'attendance', 'leaves', 'payroll', 'jwt_tokens')
ORDER BY tablename;

-- Show RLS policies
SELECT
  schemaname,
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
