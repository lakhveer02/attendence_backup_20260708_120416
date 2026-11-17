#!/usr/bin/env python3
"""
Debug Profiles Query
Check what's in the profiles table
"""

import os
from supabase import create_client
from dotenv import load_dotenv

load_dotenv()

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_SERVICE_KEY", os.getenv("SUPABASE_ANON_KEY"))
COMPANY_ID = "01e20568-18c6-4020-a3b3-6c717a023baf"

def main():
    print("=" * 70)
    print("🔍 DEBUGGING PROFILES QUERY")
    print("=" * 70)
    print()
    
    supabase = create_client(SUPABASE_URL, SUPABASE_KEY)
    
    # Test 1: Get all profiles for company
    print("Test 1: All profiles for company (no filter)")
    response = supabase.table("profiles").select("id, email, is_active").eq("company_id", COMPANY_ID).execute()
    print(f"Count: {len(response.data)}")
    for profile in response.data:
        print(f"  - {profile['email']}: is_active={profile.get('is_active')}")
    print()
    
    # Test 2: Count with is_active = True
    print("Test 2: Count with is_active=True (boolean)")
    response = supabase.table("profiles").select("id", count="exact").eq("company_id", COMPANY_ID).eq("is_active", True).execute()
    print(f"Count: {response.count}")
    print()
    
    # Test 3: Count with is.true
    print("Test 3: Count with is.true")
    response = supabase.table("profiles").select("id", count="exact").eq("company_id", COMPANY_ID).is_("is_active", "true").execute()
    print(f"Count: {response.count}")
    print()
    
    # Test 4: Get all data with boolean filter
    print("Test 4: Get all with is_active=True filter")
    response = supabase.table("profiles").select("*").eq("company_id", COMPANY_ID).eq("is_active", True).execute()
    print(f"Count: {len(response.data)}")
    print()
    
    # Test 5: Check if is_active column exists and has correct values
    print("Test 5: Sample profile data")
    response = supabase.table("profiles").select("*").eq("company_id", COMPANY_ID).limit(1).execute()
    if response.data:
        print("Sample profile:")
        print(response.data[0])
    print()
    
    print("=" * 70)


if __name__ == "__main__":
    main()
