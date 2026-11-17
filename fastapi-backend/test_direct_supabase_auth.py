#!/usr/bin/env python3
"""
Test Direct Supabase Authentication
Tests if Supabase Auth is working correctly
"""

import os
import sys
from supabase import create_client
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_SERVICE_KEY", os.getenv("SUPABASE_ANON_KEY"))

# Test credentials
TEST_USERS = [
    {"email": "chanten.batra@company.com", "password": "Ceo@1234"},
    {"email": "deepak.batra@company.com", "password": "Hr@1234"},
    {"email": "gurmeet.singh@company.com", "password": "Dev@1234"},
]


def test_auth(supabase, email, password):
    """Test authentication for a user"""
    print(f"\nTesting: {email}")
    print(f"Password: {password}")
    
    try:
        # Try to sign in
        response = supabase.auth.sign_in_with_password({
            "email": email,
            "password": password
        })
        
        if response.user:
            print(f"✅ SUCCESS - User ID: {response.user.id}")
            print(f"   Email: {response.user.email}")
            return True
        else:
            print(f"❌ FAILED - No user returned")
            return False
            
    except Exception as e:
        print(f"❌ ERROR: {e}")
        return False


def main():
    """Main test"""
    try:
        print("=" * 70)
        print("🔐 DIRECT SUPABASE AUTH TEST")
        print("=" * 70)
        print()
        
        # Connect
        print("📡 Connecting...")
        supabase = create_client(SUPABASE_URL, SUPABASE_KEY)
        print("✅ Connected")
        
        # Test each user
        print()
        print("=" * 70)
        print("Testing Authentication")
        print("=" * 70)
        
        results = []
        for user in TEST_USERS:
            success = test_auth(supabase, user['email'], user['password'])
            results.append(success)
        
        # Summary
        print()
        print("=" * 70)
        print(f"✅ Successful: {sum(results)}/{len(results)}")
        print(f"❌ Failed: {len(results) - sum(results)}/{len(results)}")
        print("=" * 70)
        
    except Exception as e:
        print(f"❌ Fatal Error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)


if __name__ == "__main__":
    main()
