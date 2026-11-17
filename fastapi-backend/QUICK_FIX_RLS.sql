-- ============================================
-- QUICK FIX: Disable RLS for Backend Access
-- Run this in Supabase SQL Editor
-- This allows the backend (using service_role key) to access all data
-- ============================================

-- Disable RLS on critical tables to allow backend access
ALTER TABLE profiles DISABLE ROW LEVEL SECURITY;
ALTER TABLE companies DISABLE ROW LEVEL SECURITY;
ALTER TABLE departments DISABLE ROW LEVEL SECURITY;
ALTER TABLE attendance DISABLE ROW LEVEL SECURITY;
ALTER TABLE leaves DISABLE ROW LEVEL SECURITY;

-- Verify RLS status
SELECT 
  schemaname,
  tablename,
  CASE 
    WHEN rowsecurity = false THEN '✅ DISABLED (Backend can access)'
    ELSE '⚠️ ENABLED (May block backend)'
  END as rls_status
FROM pg_tables
WHERE schemaname = 'public'
AND tablename IN ('profiles', 'companies', 'departments', 'attendance', 'leaves')
ORDER BY tablename;

-- Success message
DO $$
BEGIN
  RAISE NOTICE '============================================';
  RAISE NOTICE '✅ RLS DISABLED - Backend can now access data';
  RAISE NOTICE '============================================';
  RAISE NOTICE '';
  RAISE NOTICE '🔄 Next steps:';
  RAISE NOTICE '1. Go back to your app';
  RAISE NOTICE '2. Try logging in again with:';
  RAISE NOTICE '   Email: lakhveer.singh@squadminds.com';
  RAISE NOTICE '   Password: Lakhveer@2024Squad';
  RAISE NOTICE '';
  RAISE NOTICE '⚠️ Note: RLS is now disabled for testing';
  RAISE NOTICE '   Re-enable with proper policies for production';
  RAISE NOTICE '============================================';
END $$;
