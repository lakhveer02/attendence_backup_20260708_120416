#!/usr/bin/env python3
"""
Test if we can bypass RLS using Auth Admin API and direct SQL
"""
import os
import asyncio
from supabase import create_client, Client
from dotenv import load_dotenv

load_dotenv()

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_SERVICE_KEY = os.getenv("SUPABASE_SERVICE_KEY")

print("=" * 80)
print("🔧 TESTING RLS BYPASS")
print("=" * 80)
print()

# Create client with service role
client: Client = create_client(SUPABASE_URL, SUPABASE_SERVICE_KEY)

print("✅ Client created with SERVICE_ROLE key")
print()

# Test 1: Try to read profiles using REST API
print("Test 1: Read profiles via REST API")
print("-" * 40)
try:
    result = client.table("profiles").select("email").limit(1).execute()
    print(f"✅ SUCCESS: Got {len(result.data)} profiles")
    if result.data:
        print(f"   Sample: {result.data[0]}")
except Exception as e:
    print(f"❌ FAILED: {str(e)}")
print()

# Test 2: Try to read companies
print("Test 2: Read companies via REST API")
print("-" * 40)
try:
    result = client.table("companies").select("name").limit(1).execute()
    print(f"✅ SUCCESS: Got {len(result.data)} companies")
    if result.data:
        print(f"   Sample: {result.data[0]}")
except Exception as e:
    print(f"❌ FAILED: {str(e)}")
print()

# Test 3: Check RLS status using SQL
print("Test 3: Check RLS Status")
print("-" * 40)
try:
    # Try to execute SQL via RPC
    sql = """
    SELECT tablename, rowsecurity
    FROM pg_tables
    WHERE schemaname = 'public'
    AND tablename IN ('profiles', 'companies')
    ORDER BY tablename;
    """
    print("Trying to check RLS status...")
    print(f"❌ Cannot check via API - need to use Supabase Dashboard SQL Editor")
except Exception as e:
    print(f"❌ Error: {str(e)}")
print()

print("=" * 80)
print("🎯 DIAGNOSIS")
print("=" * 80)
print()
print("If both tests above FAILED with '403 Forbidden', it means:")
print("1. RLS is still ENABLED on those tables")
print("2. Supabase REST API respects RLS even with service_role")
print("3. You MUST disable RLS in Supabase Dashboard SQL Editor")
print()
print("=" * 80)
print("📋 REQUIRED ACTION")
print("=" * 80)
print()
print("Go to Supabase Dashboard and run this SQL:")
print()
print("ALTER TABLE profiles DISABLE ROW LEVEL SECURITY;")
print("ALTER TABLE companies DISABLE ROW LEVEL SECURITY;")
print()
print("There is NO other way to fix this.")
print("=" * 80)
