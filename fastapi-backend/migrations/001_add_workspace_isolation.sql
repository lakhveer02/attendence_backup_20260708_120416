-- =====================================================
-- MIGRATION: Add Workspace Isolation to All Tables
-- Purpose: Enforce strict multi-tenant data isolation
-- CRITICAL: Every table MUST have workspace_id
-- =====================================================

-- Step 1: Add workspace_id to profiles table (if not exists)
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'profiles' AND column_name = 'workspace_id'
    ) THEN
        ALTER TABLE profiles ADD COLUMN IF NOT EXISTS workspace_id UUID;
        UPDATE profiles SET workspace_id = company_id WHERE workspace_id IS NULL;
        ALTER TABLE profiles ALTER COLUMN workspace_id SET NOT NULL;
        CREATE INDEX IF NOT EXISTS idx_profiles_workspace_id ON profiles(workspace_id);
        ALTER TABLE profiles 
        ADD CONSTRAINT fk_profiles_workspace 
        FOREIGN KEY (workspace_id) REFERENCES companies(id) ON DELETE CASCADE;
    END IF;
END $$;

-- Step 2: Add workspace_id to attendance table
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'attendance' AND column_name = 'workspace_id'
    ) THEN
        ALTER TABLE attendance ADD COLUMN workspace_id UUID;
        UPDATE attendance a
        SET workspace_id = p.workspace_id
        FROM profiles p
        WHERE a.profile_id = p.id AND a.workspace_id IS NULL;
        ALTER TABLE attendance ALTER COLUMN workspace_id SET NOT NULL;
        CREATE INDEX IF NOT EXISTS idx_attendance_workspace_id ON attendance(workspace_id);
        ALTER TABLE attendance 
        ADD CONSTRAINT fk_attendance_workspace 
        FOREIGN KEY (workspace_id) REFERENCES companies(id) ON DELETE CASCADE;
    END IF;
END $$;

-- Step 3: Add workspace_id to leaves table
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'leaves' AND column_name = 'workspace_id'
    ) THEN
        ALTER TABLE leaves ADD COLUMN workspace_id UUID;
        UPDATE leaves l
        SET workspace_id = p.workspace_id
        FROM profiles p
        WHERE l.profile_id = p.id AND l.workspace_id IS NULL;
        ALTER TABLE leaves ALTER COLUMN workspace_id SET NOT NULL;
        CREATE INDEX IF NOT EXISTS idx_leaves_workspace_id ON leaves(workspace_id);
        ALTER TABLE leaves 
        ADD CONSTRAINT fk_leaves_workspace 
        FOREIGN KEY (workspace_id) REFERENCES companies(id) ON DELETE CASCADE;
    END IF;
END $$;

-- Step 4: Add workspace_id to departments table
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'departments' AND column_name = 'workspace_id'
    ) THEN
        ALTER TABLE departments ADD COLUMN workspace_id UUID;
        UPDATE departments SET workspace_id = company_id WHERE workspace_id IS NULL AND company_id IS NOT NULL;
        UPDATE departments 
        SET workspace_id = (SELECT id FROM companies LIMIT 1)
        WHERE workspace_id IS NULL;
        ALTER TABLE departments ALTER COLUMN workspace_id SET NOT NULL;
        CREATE INDEX IF NOT EXISTS idx_departments_workspace_id ON departments(workspace_id);
        ALTER TABLE departments 
        ADD CONSTRAINT fk_departments_workspace 
        FOREIGN KEY (workspace_id) REFERENCES companies(id) ON DELETE CASCADE;
    END IF;
END $$;

-- Step 5: Add workspace_id to face_embeddings table
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'face_embeddings' AND column_name = 'workspace_id'
    ) THEN
        ALTER TABLE face_embeddings ADD COLUMN workspace_id UUID;
        UPDATE face_embeddings fe
        SET workspace_id = p.workspace_id
        FROM profiles p
        WHERE fe.profile_id = p.id AND fe.workspace_id IS NULL;
        ALTER TABLE face_embeddings ALTER COLUMN workspace_id SET NOT NULL;
        CREATE INDEX IF NOT EXISTS idx_face_embeddings_workspace_id ON face_embeddings(workspace_id);
        ALTER TABLE face_embeddings 
        ADD CONSTRAINT fk_face_embeddings_workspace 
        FOREIGN KEY (workspace_id) REFERENCES companies(id) ON DELETE CASCADE;
    END IF;
END $$;

-- Step 6: FIXED VIA DYNAMIC SQL FOR REFRESH TOKENS TABLE
DO $$ 
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_name = 'refresh_tokens'
    ) THEN
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'refresh_tokens' AND column_name = 'workspace_id'
        ) THEN
            -- Using EXECUTE forces runtime evaluation, skipping compile-time relation checks
            EXECUTE 'ALTER TABLE refresh_tokens ADD COLUMN workspace_id UUID';
            EXECUTE 'UPDATE refresh_tokens rt SET workspace_id = p.workspace_id FROM profiles p WHERE rt.profile_id = p.id AND rt.workspace_id IS NULL';
            EXECUTE 'ALTER TABLE refresh_tokens ALTER COLUMN workspace_id SET NOT NULL';
            EXECUTE 'CREATE INDEX IF NOT EXISTS idx_refresh_tokens_workspace_id ON refresh_tokens(workspace_id)';
            EXECUTE 'ALTER TABLE refresh_tokens ADD CONSTRAINT fk_refresh_tokens_workspace FOREIGN KEY (workspace_id) REFERENCES companies(id) ON DELETE CASCADE';
        END IF;
    END IF;
END $$;

-- Step 7: Create Row-Level Security (RLS) Policies
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS workspace_isolation_policy ON profiles;
CREATE POLICY workspace_isolation_policy ON profiles
    USING (workspace_id = current_setting('app.current_workspace_id', true)::uuid)
    WITH CHECK (workspace_id = current_setting('app.current_workspace_id', true)::uuid);

ALTER TABLE attendance ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS workspace_isolation_policy ON attendance;
CREATE POLICY workspace_isolation_policy ON attendance
    USING (workspace_id = current_setting('app.current_workspace_id', true)::uuid);

ALTER TABLE leaves ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS workspace_isolation_policy ON leaves;
CREATE POLICY workspace_isolation_policy ON leaves
    USING (workspace_id = current_setting('app.current_workspace_id', true)::uuid);

ALTER TABLE departments ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS workspace_isolation_policy ON departments;
CREATE POLICY workspace_isolation_policy ON departments
    USING (workspace_id = current_setting('app.current_workspace_id', true)::uuid);

-- Step 8: Create helper function to set workspace context
CREATE OR REPLACE FUNCTION set_workspace_context(workspace_uuid UUID)
RETURNS void AS $$
BEGIN
    PERFORM set_config('app.current_workspace_id', workspace_uuid::text, true);
END;
$$ LANGUAGE plpgsql;

-- Step 9: Add unique constraints that respect workspace boundaries
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'unique_employee_id_per_workspace'
    ) THEN
        ALTER TABLE profiles ADD COLUMN IF NOT EXISTS employee_id VARCHAR(50);
        ALTER TABLE profiles 
        ADD CONSTRAINT unique_employee_id_per_workspace 
        UNIQUE (workspace_id, employee_id);
        CREATE INDEX IF NOT EXISTS idx_profiles_employee_id ON profiles(workspace_id, employee_id);
    END IF;
END $$;

-- Step 10: Add reporting_manager_id for hierarchy
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'profiles' AND column_name = 'reporting_manager_id'
    ) THEN
        ALTER TABLE profiles ADD COLUMN reporting_manager_id UUID;
        ALTER TABLE profiles 
        ADD CONSTRAINT fk_reporting_manager 
        FOREIGN KEY (reporting_manager_id) REFERENCES profiles(id) ON DELETE SET NULL;
        CREATE INDEX IF NOT EXISTS idx_profiles_reporting_manager ON profiles(reporting_manager_id);
    END IF;
END $$;

-- Step 11: Add company/workspace metadata columns
ALTER TABLE companies ADD COLUMN IF NOT EXISTS workspace_slug VARCHAR(100) UNIQUE;
ALTER TABLE companies ADD COLUMN IF NOT EXISTS joining_token VARCHAR(8) UNIQUE;
ALTER TABLE companies ADD COLUMN IF NOT EXISTS subscription_plan VARCHAR(50) DEFAULT 'free';
ALTER TABLE companies ADD COLUMN IF NOT EXISTS subscription_status VARCHAR(50) DEFAULT 'active';
ALTER TABLE companies ADD COLUMN IF NOT EXISTS max_employees INTEGER DEFAULT 50;
ALTER TABLE companies ADD COLUMN IF NOT EXISTS employee_count INTEGER DEFAULT 0;

CREATE INDEX IF NOT EXISTS idx_companies_workspace_slug ON companies(workspace_slug);
CREATE INDEX IF NOT EXISTS idx_companies_joining_token ON companies(joining_token);

-- Step 12: Create function to auto-generate employee ID
CREATE OR REPLACE FUNCTION generate_employee_id(workspace_uuid UUID)
RETURNS VARCHAR(50) AS $$
DECLARE
    year_part TEXT;
    sequence_num INTEGER;
    employee_id TEXT;
BEGIN
    year_part := TO_CHAR(CURRENT_DATE, 'YYYY');
    SELECT COALESCE(MAX(
        CAST(
            SUBSTRING(employee_id FROM 'EMP-' || year_part || '-([0-9]+)') 
            AS INTEGER
        )
    ), 0) + 1
    INTO sequence_num
    FROM profiles
    WHERE workspace_id = workspace_uuid 
    AND employee_id LIKE 'EMP-' || year_part || '-%';
    
    employee_id := 'EMP-' || year_part || '-' || LPAD(sequence_num::TEXT, 3, '0');
    RETURN employee_id;
END;
$$ LANGUAGE plpgsql;

-- Step 13: Create function to update employee count
CREATE OR REPLACE FUNCTION update_employee_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE companies 
        SET employee_count = employee_count + 1
        WHERE id = NEW.workspace_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE companies 
        SET employee_count = GREATEST(employee_count - 1, 0)
        WHERE id = OLD.workspace_id;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_employee_count ON profiles;
CREATE TRIGGER trigger_update_employee_count
    AFTER INSERT OR DELETE ON profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_employee_count();

-- Step 14: Initialize employee counts for existing workspaces
UPDATE companies c
SET employee_count = (
    SELECT COUNT(*) 
    FROM profiles p 
    WHERE p.workspace_id = c.id
);

-- Step 15: Create audit log table for security monitoring
CREATE TABLE IF NOT EXISTS workspace_audit_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    user_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
    action VARCHAR(100) NOT NULL,
    resource_type VARCHAR(100),
    resource_id UUID,
    details JSONB,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_audit_workspace ON workspace_audit_log(workspace_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_user ON workspace_audit_log(user_id, created_at DESC);

-- Step 16: Add default departments for new workspaces
CREATE OR REPLACE FUNCTION initialize_default_departments(workspace_uuid UUID)
RETURNS void AS $$
DECLARE
    dept_names TEXT[] := ARRAY['HR', 'Engineering', 'Sales', 'Marketing', 'Finance', 'Support', 'Operations'];
    dept_name TEXT;
BEGIN
    FOREACH dept_name IN ARRAY dept_names
    LOOP
        INSERT INTO departments (workspace_id, name, created_at, updated_at)
        VALUES (workspace_uuid, dept_name, NOW(), NOW())
        ON CONFLICT DO NOTHING;
    END LOOP;
END;
$$ LANGUAGE plpgsql;