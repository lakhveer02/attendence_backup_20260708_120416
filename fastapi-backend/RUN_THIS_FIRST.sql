-- ============================================
-- SQUADMINDS HRMS - MINIMAL SETUP (NO RLS INITIALLY)
-- Run this if you keep getting "relation does not exist" error
-- 
-- This script:
-- 1. Creates all tables WITHOUT RLS
-- 2. Lets you insert data freely
-- 3. You can enable RLS later once data is inserted
-- ============================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Drop existing tables if any (BE CAREFUL - THIS DELETES DATA!)
DROP TABLE IF EXISTS audit_logs CASCADE;
DROP TABLE IF EXISTS jwt_tokens CASCADE;
DROP TABLE IF EXISTS payroll CASCADE;
DROP TABLE IF EXISTS leaves CASCADE;
DROP TABLE IF EXISTS attendance CASCADE;
DROP TABLE IF EXISTS departments CASCADE;
DROP TABLE IF EXISTS profiles CASCADE;
DROP TABLE IF EXISTS companies CASCADE;

-- ============================================
-- CREATE TABLES (WITHOUT RLS ENABLED)
-- ============================================

-- 1. COMPANIES
CREATE TABLE companies (
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

-- 2. PROFILES (No RLS yet)
CREATE TABLE profiles (
    id UUID PRIMARY KEY,
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
    last_login TIMESTAMP,
    CHECK (role IN ('super_admin', 'company_admin', 'hr_manager', 'manager', 'employee'))
);

-- 3. DEPARTMENTS
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

-- 4. ATTENDANCE
CREATE TABLE attendance (
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
    updated_at TIMESTAMP DEFAULT NOW(),
    CHECK (status IN ('present', 'absent', 'late', 'half_day', 'on_leave')),
    CHECK (verification_method IN ('biometric', 'face', 'manual', 'hybrid'))
);

-- 5. LEAVES
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

-- 6. PAYROLL
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

-- 7. JWT_TOKENS
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
-- CREATE INDEXES
-- ============================================

CREATE INDEX idx_companies_workspace_slug ON companies(workspace_slug);
CREATE INDEX idx_companies_status ON companies(status);

CREATE INDEX idx_profiles_company_id ON profiles(company_id);
CREATE INDEX idx_profiles_email ON profiles(email);
CREATE INDEX idx_profiles_role ON profiles(role);
CREATE INDEX idx_profiles_department_id ON profiles(department_id);

CREATE INDEX idx_departments_company_id ON departments(company_id);

CREATE INDEX idx_attendance_company_id ON attendance(company_id);
CREATE INDEX idx_attendance_profile_id ON attendance(profile_id);
CREATE INDEX idx_attendance_check_in ON attendance(check_in);

CREATE INDEX idx_leaves_company_id ON leaves(company_id);
CREATE INDEX idx_leaves_profile_id ON leaves(profile_id);
CREATE INDEX idx_leaves_status ON leaves(status);

CREATE INDEX idx_payroll_company_id ON payroll(company_id);
CREATE INDEX idx_payroll_profile_id ON payroll(profile_id);

CREATE INDEX idx_jwt_tokens_profile_id ON jwt_tokens(profile_id);
CREATE INDEX idx_jwt_tokens_token_id ON jwt_tokens(token_id);

-- ============================================
-- VERIFICATION
-- ============================================

DO $$
BEGIN
    RAISE NOTICE '============================================';
    RAISE NOTICE '✅ TABLES CREATED SUCCESSFULLY!';
    RAISE NOTICE '============================================';
    RAISE NOTICE '';
    RAISE NOTICE '⚠️  IMPORTANT: RLS is DISABLED for now';
    RAISE NOTICE '   This allows data insertion without errors.';
    RAISE NOTICE '';
    RAISE NOTICE '📋 Next steps:';
    RAISE NOTICE '  1. Run: python create_squadminds_company.py';
    RAISE NOTICE '  2. Verify data is inserted';
    RAISE NOTICE '  3. Then enable RLS (optional for development)';
    RAISE NOTICE '';
    RAISE NOTICE '💡 Tables created:';
    RAISE NOTICE '  • companies';
    RAISE NOTICE '  • profiles';
    RAISE NOTICE '  • departments';
    RAISE NOTICE '  • attendance';
    RAISE NOTICE '  • leaves';
    RAISE NOTICE '  • payroll';
    RAISE NOTICE '  • jwt_tokens';
    RAISE NOTICE '';
END $$;

-- Show created tables
SELECT 
    tablename as "Table Name",
    pg_size_pretty(pg_total_relation_size('public.'||tablename)) as "Size"
FROM pg_tables
WHERE schemaname = 'public'
AND tablename IN ('companies', 'profiles', 'departments', 'attendance', 'leaves', 'payroll', 'jwt_tokens')
ORDER BY tablename;
