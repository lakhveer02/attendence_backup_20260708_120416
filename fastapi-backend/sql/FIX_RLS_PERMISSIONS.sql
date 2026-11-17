-- FIX RLS PERMISSIONS FOR SERVICE ROLE
-- Run this in Supabase SQL Editor to allow backend to read profiles

-- The service_role should bypass RLS, but if it's not working, we need to ensure it
-- Option 1: Disable RLS on profiles table (NOT RECOMMENDED FOR PRODUCTION)
-- ALTER TABLE profiles DISABLE ROW LEVEL SECURITY;

-- Option 2: Add explicit policy for service_role (BETTER)
-- First, check if service_role can bypass RLS
-- SELECT usebypassrls FROM pg_roles WHERE rolname = 'service_role';
-- Should return 't' (true)

-- If the issue persists, create explicit policies for service_role
-- Drop existing policies that might be blocking
DROP POLICY IF EXISTS "Service role can read all profiles" ON profiles;
DROP POLICY IF EXISTS "Service role has full access" ON profiles;

-- Create policy allowing service_role full access
CREATE POLICY "Service role has full access"
ON profiles
FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

-- Ensure authenticated users can read their own profiles
DROP POLICY IF EXISTS "Users can read own profile" ON profiles;
CREATE POLICY "Users can read own profile"
ON profiles
FOR SELECT
TO authenticated
USING (auth.uid() = id);

-- Ensure company admins can read all company profiles
DROP POLICY IF EXISTS "Company admins can read company profiles" ON profiles;
CREATE POLICY "Company admins can read company profiles"
ON profiles
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM profiles p
    WHERE p.id = auth.uid()
    AND p.company_id = profiles.company_id
    AND p.role IN ('company_admin', 'super_admin')
  )
);

-- Verify the service_role can bypass RLS
SELECT 
  usebypassrls as "Can Bypass RLS",
  rolname as "Role Name"
FROM pg_roles 
WHERE rolname = 'service_role';

-- Test query
SELECT COUNT(*) as employee_count 
FROM profiles 
WHERE company_id = '01e20568-18c6-4020-a3b3-6c717a023baf' 
AND is_active = true;
