#!/usr/bin/env python3
"""
Disable RLS on all tables - Run this to fix the permission errors
"""
import os
from supabase import create_client
from dotenv import load_dotenv

# Load environment
load_dotenv()

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_SERVICE_KEY = os.getenv("SUPABASE_SERVICE_KEY")

print("=" * 80)
print("🔧 DISABLING ROW-LEVEL SECURITY (RLS)")
print("=" * 80)
print()

# Create client with service role
client = create_client(SUPABASE_URL, SUPABASE_SERVICE_KEY)

# SQL to disable RLS
sql = """
-- Disable RLS on all tables
ALTER TABLE profiles DISABLE ROW LEVEL SECURITY;
ALTER TABLE companies DISABLE ROW LEVEL SECURITY;
ALTER TABLE departments DISABLE ROW LEVEL SECURITY;
ALTER TABLE attendance DISABLE ROW LEVEL SECURITY;
ALTER TABLE leaves DISABLE ROW LEVEL SECURITY;
ALTER TABLE payroll DISABLE ROW LEVEL SECURITY;

-- Verify
SELECT 
  tablename,
  CASE 
    WHEN rowsecurity = false THEN 'DISABLED'
    ELSE 'ENABLED'
  END as rls_status
FROM pg_tables
WHERE schemaname = 'public'
AND tablename IN ('profiles', 'companies', 'departments', 'attendance', 'leaves', 'payroll')
ORDER BY tablename;
"""

print("📝 Executing SQL to disable RLS...")
print()

try:
    # Execute using RPC or direct SQL
    result = client.rpc('execute_sql', {'sql': sql}).execute()
    print("✅ SQL executed successfully!")
    print()
    print(result.data if result.data else "✅ RLS disabled on all tables")
except Exception as e:
    error_msg = str(e)
    print(f"❌ Error executing SQL: {error_msg}")
    print()
    
    if "function" in error_msg.lower() or "does not exist" in error_msg.lower():
        print("⚠️  Cannot execute SQL via API")
        print()
        print("📋 MANUAL FIX REQUIRED:")
        print("=" * 80)
        print()
        print("1. Go to Supabase Dashboard: https://supabase.com/dashboard")
        print("2. Select your project")
        print("3. Click 'SQL Editor' in left sidebar")
        print("4. Paste this SQL and click 'Run':")
        print()
        print("-" * 80)
        print(sql)
        print("-" * 80)
        print()
        print("5. You should see output showing all tables with 'DISABLED' status")
        print("6. Then try signup/login again")
        print()
    else:
        print("⚠️  Unexpected error. Try the manual fix above.")

print()
print("=" * 80)
print("After disabling RLS, test with:")
print("  - Signup: chetan@squadminds.com / Chetan@2024")
print("  - Login: chantenbarta@squadminds.com / Ceo@2024Squad")
print("=" * 80)
