-- ============================================
-- SQUADMINDS HRMS - COMPLETE FRESH START
-- ============================================
-- This script will:
-- 1. DROP all existing tables (deletes all data!)
-- 2. CREATE all tables from scratch
-- 3. Add all indexes and constraints
-- 4. Enable RLS with bug fixes
-- 
-- ⚠️  WARNING: This DELETES ALL DATA!
-- ============================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- STEP 1: DROP ALL EXISTING TABLES
-- ============================================

DROP TABLE IF EXISTS audit_logs CASCADE;
DROP TABLE IF EXISTS jwt_tokens CASCADE;
DROP TABLE IF EXISTS payroll CASCADE;
DROP TABLE IF EXISTS leaves CASCADE;
DROP TABLE IF EXISTS attendance CASCADE;
DROP TABLE IF EXISTS departments CASCADE;
DROP TABLE IF EXISTS profiles CASCADE;
DROP TABLE IF EXISTS companies CASCADE;

-- ============================================
-- STEP 2: CREATE ALL TABLES
-- ============================================

-- 1. COMPANIES TABLE
CREATE TABLE companies (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(200) NOT NULL,
    workspace_slug VARCHAR(100) UNIQUE,
    joining_token VARCHAR(8) UNIQUE,
    industry VARCHAR(100),
    status VARCHAR(50) DEFAULT 'active',
    timezone VARCHAR(50) DEFAULT 'UTC',
    
    -- Office location for geofencing (BUG FIX #2)
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

COMMENT ON TABLE companies IS 'Multi-tenant companies/organizations';
COMMENT ON COLUMN companies.office_latitude IS 'Office GPS latitude for dynamic geofencing';
COMMENT ON COLUMN companies.office_longitude IS 'Office GPS longitude for dynamic geofencing';

-- 2. PROFILES TABLE (Users)
CREATE TABLE profiles (
    id UUID PRIMARY KEY,
    company_id UUID REFERENCES companies(id) ON DELETE CASCADE,
    workspace_id UUID REFERENCES companies(id) ON DELETE CASCADE,
    
    email VARCHAR(255) UNIQUE NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    phone_number VARCHAR(20),
    
    -- RBAC role (BUG FIX #3: supports 'manager' not 'team_manager')
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
    last_login TIMESTAMP,
    
    CHECK (role IN ('super_admin', 'company_admin', 'hr_manager', 'manager', 'employee'))
);

COMMENT ON TABLE profiles IS 'User profiles with RBAC roles';
COMMENT ON COLUMN profiles.role IS 'Valid roles: super_admin, company_admin, hr_manager, manager, employee';

-- 3. DEPARTMENTS TABLE
CREATE TABLE departments (
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

-- 4. ATTENDANCE TABLE
CREATE TABLE attendance (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    
    check_in TIMESTAMP NOT NULL,
    check_out TIMESTAMP,
    total_hours DECIMAL(5, 2),
    status VARCHAR(50) DEFAULT 'present',
    
    -- GPS tracking
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
    updated_at TIMESTAMP DEFAULT NOW(),
    
    CHECK (status IN ('present', 'absent', 'late', 'half_day', 'on_leave')),
    CHECK (verification_method IN ('biometric', 'face', 'manual', 'hybrid'))
);

COMMENT ON TABLE attendance IS 'Daily attendance with GPS geofencing';

-- 5. LEAVES TABLE
CREATE TABLE leaves (
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
    updated_at TIMESTAMP DEFAULT NOW(),
    
    CHECK (leave_type IN ('sick', 'casual', 'earned', 'unpaid', 'maternity', 'paternity', 'compensatory', 'bereavement')),
    CHECK (status IN ('pending', 'approved', 'rejected', 'cancelled'))
);

-- 6. PAYROLL TABLE
CREATE TABLE payroll (
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
    
    CHECK (status IN ('draft', 'processed', 'paid')),
    UNIQUE(company_id, profile_id, month, year)
);

-- 7. JWT_TOKENS TABLE
CREATE TABLE jwt_tokens (
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

-- ============================================
-- STEP 3: CREATE INDEXES
-- ============================================

-- Companies indexes
CREATE INDEX idx_companies_workspace_slug ON companies(workspace_slug);
CREATE INDEX idx_companies_status ON companies(status);

-- Profiles indexes
CREATE INDEX idx_profiles_company_id ON profiles(company_id);
CREATE INDEX idx_profiles_email ON profiles(email);
CREATE INDEX idx_profiles_role ON profiles(role);
CREATE INDEX idx_profiles_department_id ON profiles(department_id);
CREATE INDEX idx_profiles_reporting_manager_id ON profiles(reporting_manager_id);

-- Departments indexes
CREATE INDEX idx_departments_company_id ON departments(company_id);
CREATE INDEX idx_departments_head_id ON departments(head_id);

-- Attendance indexes
CREATE INDEX idx_attendance_company_id ON attendance(company_id);
CREATE INDEX idx_attendance_profile_id ON attendance(profile_id);
CREATE INDEX idx_attendance_check_in ON attendance(check_in);
CREATE INDEX idx_attendance_date ON attendance(DATE(check_in));

-- Leaves indexes
CREATE INDEX idx_leaves_company_id ON leaves(company_id);
CREATE INDEX idx_leaves_profile_id ON leaves(profile_id);
CREATE INDEX idx_leaves_status ON leaves(status);
CREATE INDEX idx_leaves_dates ON leaves(start_date, end_date);

-- Payroll indexes
CREATE INDEX idx_payroll_company_id ON payroll(company_id);
CREATE INDEX idx_payroll_profile_id ON payroll(profile_id);
CREATE INDEX idx_payroll_period ON payroll(year, month);
CREATE INDEX idx_payroll_status ON payroll(status);

-- JWT tokens indexes
CREATE INDEX idx_jwt_tokens_profile_id ON jwt_tokens(profile_id);
CREATE INDEX idx_jwt_tokens_token_id ON jwt_tokens(token_id);
CREATE INDEX idx_jwt_tokens_device_id ON jwt_tokens(device_id);
CREATE INDEX idx_jwt_tokens_expires_at ON jwt_tokens(expires_at);

-- ============================================
-- STEP 4: ENABLE RLS WITH BUG FIXES
-- ============================================

-- Enable RLS on critical tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE companies ENABLE ROW LEVEL SECURITY;
ALTER TABLE departments ENABLE ROW LEVEL SECURITY;

-- ============================================
-- PROFILES TABLE POLICIES (BUG FIX #1)
-- ============================================

-- Policy 1: Users can read their own profile
CREATE POLICY "Users can read own profile"
ON profiles FOR SELECT
USING (auth.uid() = id);

-- Policy 2: Users can read all profiles in their company
-- BUG FIX #1: Use JWT metadata to avoid infinite recursion
CREATE POLICY "Users can read company profiles"
ON profiles FOR SELECT
USING (
  company_id = COALESCE(
    (auth.jwt() ->> 'company_id')::uuid,
    (SELECT raw_app_meta_data->>'company_id' FROM auth.users WHERE id = auth.uid())::uuid
  )
);

-- Policy 3: Users can update their own profile
CREATE POLICY "Users can update own profile"
ON profiles FOR UPDATE
USING (auth.uid() = id);

-- Policy 4: Service role and admins can create profiles
-- BUG FIX #1: No recursive query here either
CREATE POLICY "Admins can create profiles"
ON profiles FOR INSERT
WITH CHECK (
  auth.role() = 'service_role'
  OR
  (auth.jwt() ->> 'role') IN ('company_admin', 'super_admin', 'hr_manager')
);

-- Policy 5: Service role has full access
CREATE POLICY "Service role full access profiles"
ON profiles FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

-- ============================================
-- COMPANIES TABLE POLICIES (BUG FIX #1)
-- ============================================

-- BUG FIX #1: Use JWT metadata instead of recursive query
CREATE POLICY "Users can read own company"
ON companies FOR SELECT
USING (
  id = COALESCE(
    (auth.jwt() ->> 'company_id')::uuid,
    (SELECT raw_app_meta_data->>'company_id' FROM auth.users WHERE id = auth.uid())::uuid
  )
);

-- BUG FIX #1: Use JWT metadata for UPDATE as well
CREATE POLICY "Admins can update own company"
ON companies FOR UPDATE
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
ON companies FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

-- ============================================
-- DEPARTMENTS TABLE POLICIES (BUG FIX #1)
-- ============================================

-- BUG FIX #1: Use JWT metadata
CREATE POLICY "Users can read company departments"
ON departments FOR SELECT
USING (
  company_id = COALESCE(
    (auth.jwt() ->> 'company_id')::uuid,
    (SELECT raw_app_meta_data->>'company_id' FROM auth.users WHERE id = auth.uid())::uuid
  )
);

CREATE POLICY "Service role full access departments"
ON departments FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

-- ============================================
-- STEP 5: VERIFICATION & SUCCESS MESSAGE
-- ============================================

DO $$
BEGIN
    RAISE NOTICE '============================================';
    RAISE NOTICE '✅ FRESH START COMPLETE!';
    RAISE NOTICE '============================================';
    RAISE NOTICE '';
    RAISE NOTICE '🎯 What was done:';
    RAISE NOTICE '  1. Dropped all old tables';
    RAISE NOTICE '  2. Created 7 new tables';
    RAISE NOTICE '  3. Added all indexes';
    RAISE NOTICE '  4. Enabled RLS with bug fixes';
    RAISE NOTICE '';
    RAISE NOTICE '🐛 Bug fixes applied:';
    RAISE NOTICE '  ✅ #1: RLS infinite recursion fixed';
    RAISE NOTICE '  ✅ #2: Dynamic geofencing ready';
    RAISE NOTICE '  ✅ #3: Role supports "manager"';
    RAISE NOTICE '';
    RAISE NOTICE '📋 Next steps:';
    RAISE NOTICE '  1. Run: python create_squadminds_company.py';
    RAISE NOTICE '  2. Test login with credentials';
    RAISE NOTICE '  3. Test check-in with geofencing';
    RAISE NOTICE '';
    RAISE NOTICE '📊 Tables created:';
    RAISE NOTICE '  • companies (with office GPS)';
    RAISE NOTICE '  • profiles (with manager role)';
    RAISE NOTICE '  • departments';
    RAISE NOTICE '  • attendance (with geofencing)';
    RAISE NOTICE '  • leaves';
    RAISE NOTICE '  • payroll';
    RAISE NOTICE '  • jwt_tokens';
    RAISE NOTICE '';
END $$;

-- Show created tables
SELECT 
    tablename as "✅ Table",
    CASE 
        WHEN tablename IN ('profiles', 'companies', 'departments') 
        THEN 'RLS Enabled'
        ELSE 'No RLS'
    END as "Security",
    pg_size_pretty(pg_total_relation_size('public.'||tablename)) as "Size"
FROM pg_tables
WHERE schemaname = 'public'
AND tablename IN ('companies', 'profiles', 'departments', 'attendance', 'leaves', 'payroll', 'jwt_tokens')
ORDER BY tablename;

-- Show RLS policies count
SELECT
  tablename,
  COUNT(*) as "Policies"
FROM pg_policies
WHERE schemaname = 'public'
AND tablename IN ('profiles', 'companies', 'departments')
GROUP BY tablename
ORDER BY tablename;
