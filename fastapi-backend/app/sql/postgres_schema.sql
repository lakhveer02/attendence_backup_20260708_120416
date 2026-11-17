DROP SCHEMA IF EXISTS public CASCADE;
CREATE SCHEMA public;
SET search_path TO public, pg_catalog;

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TABLE public.users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    role VARCHAR(50) NOT NULL DEFAULT 'employee',
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE public.departments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    code VARCHAR(50) UNIQUE,
    description TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE public.designations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(255) NOT NULL,
    department_id UUID REFERENCES public.departments(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE public.shifts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    work_days VARCHAR(50) NOT NULL DEFAULT '1,2,3,4,5',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE public.employees (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    employee_code VARCHAR(100) UNIQUE,
    full_name VARCHAR(255) NOT NULL,
    department_id UUID REFERENCES public.departments(id) ON DELETE SET NULL,
    designation_id UUID REFERENCES public.designations(id) ON DELETE SET NULL,
    shift_id UUID REFERENCES public.shifts(id) ON DELETE SET NULL,
    joining_date DATE NOT NULL,
    salary_currency VARCHAR(10) NOT NULL DEFAULT 'INR',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE public.salary_structures (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    employee_id UUID REFERENCES public.employees(id) ON DELETE CASCADE,
    basic_salary NUMERIC(12,2) NOT NULL DEFAULT 0,
    hra NUMERIC(12,2) NOT NULL DEFAULT 0,
    allowances NUMERIC(12,2) NOT NULL DEFAULT 0,
    bonus NUMERIC(12,2) NOT NULL DEFAULT 0,
    incentives NUMERIC(12,2) NOT NULL DEFAULT 0,
    deductions NUMERIC(12,2) NOT NULL DEFAULT 0,
    pf NUMERIC(12,2) NOT NULL DEFAULT 0,
    esi NUMERIC(12,2) NOT NULL DEFAULT 0,
    tds NUMERIC(12,2) NOT NULL DEFAULT 0,
    other_deductions NUMERIC(12,2) NOT NULL DEFAULT 0,
    effective_from DATE NOT NULL DEFAULT CURRENT_DATE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE public.attendance (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    employee_id UUID REFERENCES public.employees(id) ON DELETE CASCADE,
    attendance_date DATE NOT NULL,
    check_in TIMESTAMPTZ,
    check_out TIMESTAMPTZ,
    status VARCHAR(30) NOT NULL DEFAULT 'present',
    location_latitude NUMERIC(9,6),
    location_longitude NUMERIC(9,6),
    device_id VARCHAR(255),
    biometric_result VARCHAR(50),
    face_match_score NUMERIC(5,2),
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT attendance_status_chk CHECK (status IN ('present','absent','half_day','leave','work_from_home','holiday','weekend'))
);

CREATE TABLE public.attendance_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    attendance_id UUID REFERENCES public.attendance(id) ON DELETE CASCADE,
    action VARCHAR(50) NOT NULL,
    payload JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE public.payroll (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    employee_id UUID REFERENCES public.employees(id) ON DELETE CASCADE,
    payroll_month VARCHAR(7) NOT NULL,
    monthly_salary NUMERIC(12,2) NOT NULL DEFAULT 0,
    per_day_salary NUMERIC(12,2) NOT NULL DEFAULT 0,
    daily_earnings NUMERIC(12,2) NOT NULL DEFAULT 0,
    overtime_pay NUMERIC(12,2) NOT NULL DEFAULT 0,
    late_penalty NUMERIC(12,2) NOT NULL DEFAULT 0,
    early_leave_penalty NUMERIC(12,2) NOT NULL DEFAULT 0,
    final_salary NUMERIC(12,2) NOT NULL DEFAULT 0,
    status VARCHAR(30) NOT NULL DEFAULT 'draft',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE public.payroll_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    payroll_id UUID REFERENCES public.payroll(id) ON DELETE CASCADE,
    transaction_type VARCHAR(50) NOT NULL,
    amount NUMERIC(12,2) NOT NULL DEFAULT 0,
    description TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE public.holidays (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    holiday_date DATE NOT NULL,
    is_recurring BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE public.leave_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    employee_id UUID REFERENCES public.employees(id) ON DELETE CASCADE,
    leave_type VARCHAR(50) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    reason TEXT NOT NULL,
    status VARCHAR(30) NOT NULL DEFAULT 'pending',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE public.notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    employee_id UUID REFERENCES public.employees(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    body TEXT NOT NULL,
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_employees_department_id ON public.employees(department_id);
CREATE INDEX IF NOT EXISTS idx_attendance_employee_date ON public.attendance(employee_id, attendance_date);
CREATE INDEX IF NOT EXISTS idx_payroll_employee_month ON public.payroll(employee_id, payroll_month);
CREATE INDEX IF NOT EXISTS idx_leave_requests_employee ON public.leave_requests(employee_id, status);
CREATE INDEX IF NOT EXISTS idx_notifications_employee ON public.notifications(employee_id, is_read);
