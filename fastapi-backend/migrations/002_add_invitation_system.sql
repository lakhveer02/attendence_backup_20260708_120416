-- =====================================================
-- MIGRATION: Add Invitation & Company Joining Code System
-- Purpose: Implement invite-based onboarding per Architecture Blueprint
-- =====================================================

-- Step 1: Create company_joining_codes table
CREATE TABLE IF NOT EXISTS company_joining_codes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    code VARCHAR(8) UNIQUE NOT NULL,
    created_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
    expires_at TIMESTAMP,
    max_uses INTEGER,
    current_uses INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_joining_codes_workspace ON company_joining_codes(workspace_id);
CREATE INDEX IF NOT EXISTS idx_joining_codes_code ON company_joining_codes(code) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_joining_codes_expires ON company_joining_codes(expires_at) WHERE is_active = TRUE;

-- Step 2: Create invitations table for direct email invitations
CREATE TABLE IF NOT EXISTS invitations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    email VARCHAR(255) NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    role VARCHAR(50) NOT NULL DEFAULT 'employee',
    department_id UUID REFERENCES departments(id) ON DELETE SET NULL,
    token VARCHAR(64) UNIQUE NOT NULL,
    invited_by UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    expires_at TIMESTAMP NOT NULL,
    status VARCHAR(20) DEFAULT 'pending', -- pending, accepted, expired, revoked
    accepted_at TIMESTAMP,
    accepted_by_user_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_invitations_workspace ON invitations(workspace_id);
CREATE INDEX IF NOT EXISTS idx_invitations_email ON invitations(email, workspace_id);
CREATE INDEX IF NOT EXISTS idx_invitations_token ON invitations(token) WHERE status = 'pending';
CREATE INDEX IF NOT EXISTS idx_invitations_status ON invitations(status);

-- Unique constraint: one pending invitation per email per workspace
CREATE UNIQUE INDEX IF NOT EXISTS idx_invitations_unique_pending 
ON invitations(email, workspace_id) 
WHERE status = 'pending';

-- Step 3: Add invitation tracking columns to profiles
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS invited_via_code VARCHAR(8);
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS invitation_id UUID REFERENCES invitations(id) ON DELETE SET NULL;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS onboarded_via VARCHAR(50); -- 'admin_created', 'joining_code', 'email_invitation'

CREATE INDEX IF NOT EXISTS idx_profiles_invited_via ON profiles(invited_via_code);
CREATE INDEX IF NOT EXISTS idx_profiles_invitation ON profiles(invitation_id);

-- Step 4: Function to auto-expire invitations
CREATE OR REPLACE FUNCTION expire_old_invitations()
RETURNS void AS $$
BEGIN
    UPDATE invitations
    SET status = 'expired', updated_at = NOW()
    WHERE status = 'pending'
      AND expires_at < NOW();
END;
$$ LANGUAGE plpgsql;

-- Step 5: Function to validate joining code
CREATE OR REPLACE FUNCTION validate_joining_code(code_input VARCHAR(8))
RETURNS TABLE (
    valid BOOLEAN,
    workspace_id UUID,
    company_name VARCHAR(200),
    error_message TEXT
) AS $$
DECLARE
    code_record RECORD;
    company_record RECORD;
BEGIN
    -- Look up code
    SELECT * INTO code_record
    FROM company_joining_codes
    WHERE code = UPPER(code_input)
      AND is_active = TRUE;
    
    -- Code not found
    IF NOT FOUND THEN
        RETURN QUERY SELECT FALSE, NULL::UUID, NULL::VARCHAR, 'Invalid joining code';
        RETURN;
    END IF;
    
    -- Check expiry
    IF code_record.expires_at IS NOT NULL AND code_record.expires_at < NOW() THEN
        RETURN QUERY SELECT FALSE, NULL::UUID, NULL::VARCHAR, 'Joining code has expired';
        RETURN;
    END IF;
    
    -- Check usage limits
    IF code_record.max_uses IS NOT NULL AND code_record.current_uses >= code_record.max_uses THEN
        RETURN QUERY SELECT FALSE, NULL::UUID, NULL::VARCHAR, 'Joining code has reached maximum uses';
        RETURN;
    END IF;
    
    -- Get company details
    SELECT * INTO company_record
    FROM companies
    WHERE id = code_record.workspace_id;
    
    -- Check company is active
    IF company_record.status != 'active' THEN
        RETURN QUERY SELECT FALSE, NULL::UUID, NULL::VARCHAR, 'Company is not active';
        RETURN;
    END IF;
    
    -- Valid code
    RETURN QUERY SELECT TRUE, code_record.workspace_id, company_record.name, NULL::TEXT;
END;
$$ LANGUAGE plpgsql;

-- Step 6: Create trigger to update invitation status when user is created
CREATE OR REPLACE FUNCTION update_invitation_on_user_creation()
RETURNS TRIGGER AS $$
BEGIN
    -- If user was created via email invitation, update invitation status
    IF NEW.invitation_id IS NOT NULL THEN
        UPDATE invitations
        SET 
            status = 'accepted',
            accepted_at = NOW(),
            accepted_by_user_id = NEW.id,
            updated_at = NOW()
        WHERE id = NEW.invitation_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_invitation_on_user_creation ON profiles;
CREATE TRIGGER trigger_update_invitation_on_user_creation
    AFTER INSERT ON profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_invitation_on_user_creation();

-- Step 7: Create view for invitation statistics
CREATE OR REPLACE VIEW invitation_statistics AS
SELECT
    i.workspace_id,
    c.name as company_name,
    COUNT(CASE WHEN i.status = 'pending' THEN 1 END) as pending_count,
    COUNT(CASE WHEN i.status = 'accepted' THEN 1 END) as accepted_count,
    COUNT(CASE WHEN i.status = 'expired' THEN 1 END) as expired_count,
    COUNT(CASE WHEN i.status = 'revoked' THEN 1 END) as revoked_count,
    COUNT(*) as total_invitations
FROM invitations i
INNER JOIN companies c ON i.workspace_id = c.id
GROUP BY i.workspace_id, c.name;

-- Step 8: Create view for joining code statistics
CREATE OR REPLACE VIEW joining_code_statistics AS
SELECT
    cjc.workspace_id,
    c.name as company_name,
    cjc.code,
    cjc.current_uses,
    cjc.max_uses,
    cjc.expires_at,
    cjc.is_active,
    COUNT(p.id) as total_employees_joined,
    cjc.created_at
FROM company_joining_codes cjc
INNER JOIN companies c ON cjc.workspace_id = c.id
LEFT JOIN profiles p ON p.invited_via_code = cjc.code
GROUP BY cjc.workspace_id, c.name, cjc.code, cjc.current_uses, cjc.max_uses, cjc.expires_at, cjc.is_active, cjc.created_at;

-- Step 9: Add audit logging for invitation events
CREATE TABLE IF NOT EXISTS invitation_audit_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    invitation_id UUID REFERENCES invitations(id) ON DELETE SET NULL,
    code VARCHAR(8),
    event_type VARCHAR(50) NOT NULL, -- 'code_generated', 'code_used', 'invitation_sent', 'invitation_accepted', 'invitation_expired'
    user_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
    email VARCHAR(255),
    metadata JSONB,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_invitation_audit_workspace ON invitation_audit_log(workspace_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_invitation_audit_event ON invitation_audit_log(event_type);

-- Step 10: Function to log invitation events
CREATE OR REPLACE FUNCTION log_invitation_event(
    p_workspace_id UUID,
    p_event_type VARCHAR(50),
    p_invitation_id UUID DEFAULT NULL,
    p_code VARCHAR(8) DEFAULT NULL,
    p_user_id UUID DEFAULT NULL,
    p_email VARCHAR(255) DEFAULT NULL,
    p_metadata JSONB DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    log_id UUID;
BEGIN
    INSERT INTO invitation_audit_log (
        workspace_id,
        invitation_id,
        code,
        event_type,
        user_id,
        email,
        metadata,
        created_at
    ) VALUES (
        p_workspace_id,
        p_invitation_id,
        p_code,
        p_event_type,
        p_user_id,
        p_email,
        p_metadata,
        NOW()
    ) RETURNING id INTO log_id;
    
    RETURN log_id;
END;
$$ LANGUAGE plpgsql;

-- Step 11: Create scheduled job function to clean up expired invitations
-- (Requires pg_cron extension or external scheduler)
CREATE OR REPLACE FUNCTION cleanup_expired_invitations()
RETURNS INTEGER AS $$
DECLARE
    expired_count INTEGER;
BEGIN
    -- Expire old pending invitations
    UPDATE invitations
    SET status = 'expired', updated_at = NOW()
    WHERE status = 'pending'
      AND expires_at < NOW();
    
    GET DIAGNOSTICS expired_count = ROW_COUNT;
    
    -- Deactivate expired joining codes
    UPDATE company_joining_codes
    SET is_active = FALSE, updated_at = NOW()
    WHERE is_active = TRUE
      AND expires_at IS NOT NULL
      AND expires_at < NOW();
    
    RETURN expired_count;
END;
$$ LANGUAGE plpgsql;

-- Step 12: Add default joining code for existing companies (optional)
-- This gives existing companies an initial joining code
DO $$
DECLARE
    company_record RECORD;
    random_code VARCHAR(8);
BEGIN
    FOR company_record IN 
        SELECT id FROM companies WHERE status = 'active'
    LOOP
        -- Generate random 8-char code
        random_code := UPPER(SUBSTRING(MD5(RANDOM()::TEXT || company_record.id::TEXT) FROM 1 FOR 8));
        
        -- Insert joining code if none exists
        INSERT INTO company_joining_codes (
            workspace_id,
            code,
            created_by,
            expires_at,
            max_uses,
            current_uses,
            is_active
        )
        SELECT 
            company_record.id,
            random_code,
            NULL,
            NOW() + INTERVAL '90 days',
            NULL,
            0,
            TRUE
        WHERE NOT EXISTS (
            SELECT 1 FROM company_joining_codes 
            WHERE workspace_id = company_record.id 
            AND is_active = TRUE
        );
    END LOOP;
END $$;

-- Migration Complete
-- Summary:
-- 1. company_joining_codes table for workspace invitation codes
-- 2. invitations table for direct email invitations
-- 3. Profile tracking columns for invitation source
-- 4. Validation and expiry functions
-- 5. Audit logging for invitation events
-- 6. Statistics views for monitoring
-- 7. Triggers for automatic status updates
