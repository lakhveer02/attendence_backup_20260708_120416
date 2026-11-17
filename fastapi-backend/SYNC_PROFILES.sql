-- ============================================================================
-- SYNC AUTH.USERS TO PROFILES TABLE
-- This ensures user data is properly saved in profiles table
-- ============================================================================

-- Step 1: Check current profile data
SELECT 
    id,
    email,
    full_name,
    role,
    company_id,
    is_active
FROM profiles
ORDER BY created_at DESC
LIMIT 10;

-- Step 2: Create trigger to auto-sync auth.users to profiles
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (
        id,
        email,
        full_name,
        role,
        company_id,
        company_name,
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
        NEW.raw_user_meta_data->>'company_id',
        NEW.raw_user_meta_data->>'company_name',
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
        company_name = EXCLUDED.company_name,
        phone_number = EXCLUDED.phone_number,
        updated_at = NOW();
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 3: Create trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT OR UPDATE ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

-- Step 4: Sync existing users from auth.users to profiles
INSERT INTO public.profiles (
    id,
    email,
    full_name,
    role,
    company_id,
    company_name,
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
    au.raw_user_meta_data->>'company_id' as company_id,
    au.raw_user_meta_data->>'company_name' as company_name,
    au.phone as phone_number,
    true as is_active,
    au.created_at,
    au.updated_at
FROM auth.users au
WHERE au.id NOT IN (SELECT id FROM profiles)
ON CONFLICT (id) DO NOTHING;

-- Step 5: Verify sync
SELECT 
    'auth.users' as source,
    COUNT(*) as count
FROM auth.users
UNION ALL
SELECT 
    'profiles' as source,
    COUNT(*) as count
FROM profiles;

-- Step 6: Show synced profiles with companies
SELECT 
    p.id,
    p.email,
    p.full_name,
    p.role,
    p.company_id,
    c.name as company_name,
    p.is_active
FROM profiles p
LEFT JOIN companies c ON p.company_id = c.id
ORDER BY p.created_at DESC
LIMIT 10;
