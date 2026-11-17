-- ============================================
-- SQUADMINDS HRMS - Complete Database Schema
-- Run this FIRST before FIX_RLS_POLICIES.sql
-- ============================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- 1. COMPANIES TABLE
-- ============================================

CREATE TABLE IF NOT EXISTS companies (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(200) NOT NULL,
    workspace_slug VARCHAR(100) UNIQUE,
    joining_token VARCHAR(8) UNIQUE,
    industry VARCHAR(100),
    status VARCHAR(50) DEFAULT 'active',
    timezone VARCHAR(50) DEFAULT 'UTC',
    
    -- Office Location (for geofencing)
    office_latitude DECIMAL(10, 8),
    office_longitude DECIMAL(11, 8),
    geofence_radius_meters INTEGER DEFAULT 100,
    
    -- Branding
    logo_url TEXT,
    
    -- Settings
    settings JSONB DEFAULT '{}'::jsonb,
    
    -- Subscription
    subscription_plan VARCHAR(50) DEFAULT 'trial',
    subscription_status VARCHAR(50) DEFAULT 'active',
    max_employees INTEGER DEFAULT 50,
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Indexes for companies
CREATE INDEX IF NOT EXISTS idx_companies_workspace_slug ON companies(workspace_slug);
CREATE INDEX IF NOT EXISTS idx_companies_status ON companies(status);

COMMENT ON TABLE companies IS 'Multi-tenant companies/organizations';
COMMENT ON COLUMN companies.office_latitude IS 'Office GPS latitude for geofencing';
COMMENT ON COLUMN companies.office_longitude IS 'Office GPS longitude for geofencing';
COMMENT ON COLUMN companies.geofence_radius_meters IS 'Allowed distance from office in meters';

-- ============================================
-- 2. PROFILES TABLE (Users)
-- ============================================

CREATE TABLE IF NOT EXISTS profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    company_id UUID REFERENCES companies(id) ON DELETE CASCADE,
    workspace_id UUID REFERENCES companies(id) ON DELETE CASCADE,
    
    -- User Identity
    email VARCHAR(255) UNIQUE NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    phone_number VARCHAR(20),
    
    -- Role-Based Access Control
    role VARCHAR(50) NOT NULL DEFAULT 'employee',
    
    -- Job Information
    employee_id VARCHAR(50),
    department_id UUID,
    department_name VARCHAR(255),
    designation VARCHAR(100),
    
    -- Reporting Structure
    reporting_manager_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
    
    -- Biometric & Security
    profile_picture_url TEXT,
    face_embedding_url TEXT,
    device_id VARCHAR(255),
    
    -- Status
    is_active BOOLEAN DEFAULT TRUE,
    is_first_login BOOLEAN DEFAULT TRUE,
    is_verified BOOLEAN DEFAULT FALSE,
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    last_login TIMESTAMP
);

-- Indexes for profiles
CREATE INDEX IF NOT EXISTS idx_profiles_company_id ON profiles(company_id);
CREATE INDEX IF NOT EXISTS idx_profiles_email ON profiles(email);
CREATE INDEX IF NOT EXISTS idx_profiles_role ON profiles(role);
CREATE INDEX IF NOT EXISTS idx_profiles_department_id ON profiles(department_id);
CREATE INDEX IF NOT EXISTS idx_profiles_reporting_manager_id ON profiles(reporting_manager_id);

-- Constraints
ALTER TABLE profiles ADD CONSTRAINT check_role 
    CHECK (role IN ('super_admin', 'company_admin', 'hr_manager', 'manager', 'employee'));

COMMENT ON TABLE profiles IS 'User profiles with RBAC roles';
COMMENT ON COLUMN profiles.role IS 'RBAC role: super_admin, company_admin, hr_manager, manager, employee';
COMMENT ON COLUMN profiles.is_first_login IS 'True if user needs to reset password and enroll biometrics';

-- ============================================
-- 3. DEPARTMENTS TABLE
-- ============================================

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

-- Indexes for departments
CREATE INDEX IF NOT EXISTS idx_departments_company_id ON departments(company_id);
CREATE INDEX IF NOT EXISTS idx_departments_head_id ON departments(head_id);

COMMENT ON TABLE departments IS 'Company departments/teams';

-- ============================================
-- 4. ATTENDANCE TABLE
-- ============================================

CREATE TABLE IF NOT EXISTS attendance (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    
    -- Check-in/out times
    check_in TIMESTAMP NOT NULL,
    check_out TIMESTAMP,
    total_hours DECIMAL(5, 2),
    
    -- Status
    status VARCHAR(50) DEFAULT 'present',
    
    -- GPS Location
    check_in_gps JSONB,
    check_out_gps JSONB,
    distance_from_office DECIMAL(10, 2),
    
    -- Work mode
    is_wfh BOOLEAN DEFAULT FALSE,
    
    -- Verification
    verification_method VARCHAR(50),
    face_match_confidence DECIMAL(5, 2),
    
    -- Device info
    device_id VARCHAR(255),
    device_model VARCHAR(100),
    device_os VARCHAR(50),
    
    notes TEXT,
    
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Indexes for attendance
CREATE INDEX IF NOT EXISTS idx_attendance_company_id ON attendance(company_id);
CREATE INDEX IF NOT EXISTS idx_attendance_profile_id ON attendance(profile_id);
CREATE INDEX IF NOT EXISTS idx_attendance_check_in ON attendance(check_in);
CREATE INDEX IF NOT EXISTS idx_attendance_date ON attendance(DATE(check_in));

-- Constraints
ALTER TABLE attendance ADD CONSTRAINT check_status 
    CHECK (status IN ('present', 'absent', 'late', 'half_day', 'on_leave'));

ALTER TABLE attendance ADD CONSTRAINT check_verification_method 
    CHECK (verification_method IN ('biometric', 'face', 'manual', 'hybrid'));

COMMENT ON TABLE attendance IS 'Daily attendance records with GPS verification';
COMMENT ON COLUMN attendance.distance_from_office IS 'Distance in meters from company office';

-- ============================================
-- 5. LEAVES TABLE
-- ============================================

CREATE TABLE IF NOT EXISTS leaves (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    
    -- Leave details
    leave_type VARCHAR(50) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    half_day BOOLEAN DEFAULT FALSE,
    total_days DECIMAL(4, 1),
    
    reason TEXT NOT NULL,
    
    -- Status
    status VARCHAR(50) DEFAULT 'pending',
    
    -- Approval
    approved_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
    approved_at TIMESTAMP,
    rejection_reason TEXT,
    
    -- Attachments
    attachment_url TEXT,
    
    -- Emergency contact
    replacement_profile_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
    emergency_contact VARCHAR(100),
    
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Indexes for leaves
CREATE INDEX IF NOT EXISTS idx_leaves_company_id ON leaves(company_id);
CREATE INDEX IF NOT EXISTS idx_leaves_profile_id ON leaves(profile_id);
CREATE INDEX IF NOT EXISTS idx_leaves_status ON leaves(status);
CREATE INDEX IF NOT EXISTS idx_leaves_dates ON leaves(start_date, end_date);

-- Constraints
ALTER TABLE leaves ADD CONSTRAINT check_leave_type 
    CHECK (leave_type IN ('sick', 'casual', 'earned', 'unpaid', 'maternity', 'paternity', 'compensatory', 'bereavement'));

ALTER TABLE leaves ADD CONSTRAINT check_leave_status 
    CHECK (status IN ('pending', 'approved', 'rejected', 'cancelled'));

COMMENT ON TABLE leaves IS 'Leave/vacation requests and approvals';

-- ============================================
-- 6. PAYROLL TABLE
-- ============================================

CREATE TABLE IF NOT EXISTS payroll (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    
    -- Period
    month INTEGER NOT NULL,
    year INTEGER NOT NULL,
    
    -- Salary components
    basic_salary DECIMAL(10, 2) NOT NULL,
    hra DECIMAL(10, 2) DEFAULT 0,
    allowances DECIMAL(10, 2) DEFAULT 0,
    bonus DECIMAL(10, 2) DEFAULT 0,
    gross_salary DECIMAL(10, 2),
    
    -- Deductions
    deductions DECIMAL(10, 2) DEFAULT 0,
    pf DECIMAL(10, 2) DEFAULT 0,
    esi DECIMAL(10, 2) DEFAULT 0,
    tds DECIMAL(10, 2) DEFAULT 0,
    
    -- Final
    net_salary DECIMAL(10, 2) NOT NULL,
    
    -- Attendance impact
    present_days INTEGER,
    absent_days INTEGER,
    leave_days INTEGER,
    working_days INTEGER DEFAULT 22,
    overtime_hours DECIMAL(5, 2) DEFAULT 0,
    late_penalty DECIMAL(10, 2) DEFAULT 0,
    
    -- Status
    status VARCHAR(50) DEFAULT 'draft',
    paid_at TIMESTAMP,
    
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    
    UNIQUE(company_id, profile_id, month, year)
);

-- Indexes for payroll
CREATE INDEX IF NOT EXISTS idx_payroll_company_id ON payroll(company_id);
CREATE INDEX IF NOT EXISTS idx_payroll_profile_id ON payroll(profile_id);
CREATE INDEX IF NOT EXISTS idx_payroll_period ON payroll(year, month);
CREATE INDEX IF NOT EXISTS idx_payroll_status ON payroll(status);

-- Constraints
ALTER TABLE payroll ADD CONSTRAINT check_payroll_status 
    CHECK (status IN ('draft', 'processed', 'paid'));

COMMENT ON TABLE payroll IS 'Monthly salary/payroll records';

-- ============================================
-- 7. JWT_TOKENS TABLE (Session Management)
-- ============================================

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

-- Indexes for jwt_tokens
CREATE INDEX IF NOT EXISTS idx_jwt_tokens_profile_id ON jwt_tokens(profile_id);
CREATE INDEX IF NOT EXISTS idx_jwt_tokens_token_id ON jwt_tokens(token_id);
CREATE INDEX IF NOT EXISTS idx_jwt_tokens_device_id ON jwt_tokens(device_id);
CREATE INDEX IF NOT EXISTS idx_jwt_tokens_expires_at ON jwt_tokens(expires_at);

COMMENT ON TABLE jwt_tokens IS 'JWT token tracking for session management and device binding';

-- ============================================
-- 8. AUDIT_LOGS TABLE
-- ============================================

CREATE TABLE IF NOT EXISTS audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID REFERENCES companies(id) ON DELETE CASCADE,
    user_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
    
    action VARCHAR(100) NOT NULL,
    resource_type VARCHAR(50),
    resource_id UUID,
    
    old_value JSONB,
    new_value JSONB,
    
    ip_address INET,
    user_agent TEXT,
    
    timestamp TIMESTAMP DEFAULT NOW()
);

-- Indexes for audit_logs
CREATE INDEX IF NOT EXISTS idx_audit_logs_company_id ON audit_logs(company_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_user_id ON audit_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_timestamp ON audit_logs(timestamp);
CREATE INDEX IF NOT EXISTS idx_audit_logs_action ON audit_logs(action);

COMMENT ON TABLE audit_logs IS 'Audit trail for all critical actions';

-- ============================================
-- FUNCTIONS AND TRIGGERS
-- ============================================

-- Update updated_at timestamp automatically
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply to all tables
CREATE TRIGGER update_companies_updated_at BEFORE UPDATE ON companies
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_departments_updated_at BEFORE UPDATE ON departments
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_attendance_updated_at BEFORE UPDATE ON attendance
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_leaves_updated_at BEFORE UPDATE ON leaves
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_payroll_updated_at BEFORE UPDATE ON payroll
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- VERIFICATION QUERY
-- ============================================

DO $$
BEGIN
    RAISE NOTICE '✅ Database schema created successfully!';
    RAISE NOTICE '';
    RAISE NOTICE 'Created tables:';
    RAISE NOTICE '  1. companies';
    RAISE NOTICE '  2. profiles';
    RAISE NOTICE '  3. departments';
    RAISE NOTICE '  4. attendance';
    RAISE NOTICE '  5. leaves';
    RAISE NOTICE '  6. payroll';
    RAISE NOTICE '  7. jwt_tokens';
    RAISE NOTICE '  8. audit_logs';
    RAISE NOTICE '';
    RAISE NOTICE '⚠️  IMPORTANT: RLS is NOT enabled yet!';
    RAISE NOTICE '   Run FIX_RLS_POLICIES.sql next to enable security.';
END $$;

-- List all created tables
SELECT 
    schemaname,
    tablename,
    CASE
        WHEN tablename = 'companies' THEN '✅ Companies'
        WHEN tablename = 'profiles' THEN '✅ Profiles (Users)'
        WHEN tablename = 'departments' THEN '✅ Departments'
        WHEN tablename = 'attendance' THEN '✅ Attendance'
        WHEN tablename = 'leaves' THEN '✅ Leaves'
        WHEN tablename = 'payroll' THEN '✅ Payroll'
        WHEN tablename = 'jwt_tokens' THEN '✅ JWT Tokens'
        WHEN tablename = 'audit_logs' THEN '✅ Audit Logs'
    END as status,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size
FROM pg_tables
WHERE schemaname = 'public'
AND tablename IN ('companies', 'profiles', 'departments', 'attendance', 'leaves', 'payroll', 'jwt_tokens', 'audit_logs')
ORDER BY tablename;
