-- ============================================
-- FIX ALL PERMISSIONS FOR SERVICE_ROLE
-- Run this in Supabase SQL Editor
-- ============================================

-- Grant ALL privileges to service_role on all tables
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO service_role;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO service_role;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO service_role;

-- Grant usage on schema
GRANT USAGE ON SCHEMA public TO service_role;

-- Grant specific permissions on each table
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.profiles TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.companies TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.departments TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.attendance TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.leaves TO service_role;

-- Make service_role owner of tables (nuclear option)
ALTER TABLE public.profiles OWNER TO postgres;
ALTER TABLE public.companies OWNER TO postgres;
ALTER TABLE public.departments OWNER TO postgres;
ALTER TABLE public.attendance OWNER TO postgres;
ALTER TABLE public.leaves OWNER TO postgres;

-- Grant postgres role to service_role
GRANT postgres TO service_role;

-- Disable RLS again (just to be sure)
ALTER TABLE public.profiles DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.companies DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.departments DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.attendance DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.leaves DISABLE ROW LEVEL SECURITY;

-- Verify permissions
SELECT 
  tablename,
  tableowner,
  CASE 
    WHEN has_table_privilege('service_role', schemaname||'.'||tablename, 'SELECT') 
    THEN '✅ CAN READ'
    ELSE '❌ CANNOT READ'
  END as read_permission,
  CASE 
    WHEN has_table_privilege('service_role', schemaname||'.'||tablename, 'INSERT') 
    THEN '✅ CAN INSERT'
    ELSE '❌ CANNOT INSERT'
  END as insert_permission
FROM pg_tables
WHERE schemaname = 'public'
AND tablename IN ('profiles', 'companies', 'departments', 'attendance', 'leaves')
ORDER BY tablename;
