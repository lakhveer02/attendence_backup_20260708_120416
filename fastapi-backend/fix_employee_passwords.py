#!/usr/bin/env python3
"""
Fix Employee Passwords
Updates passwords for all employees in Supabase Auth
"""

import os
import sys
from supabase import create_client
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_SERVICE_KEY", os.getenv("SUPABASE_ANON_KEY"))

# Employee credentials
EMPLOYEES = [
    {"email": "chanten.batra@company.com", "password": "Ceo@1234"},
    {"email": "deepak.batra@company.com", "password": "Hr@1234"},
    {"email": "paryanshi@company.com", "password": "Hr@1234"},
    {"email": "dev.gangwar@company.com", "password": "Manager@1234"},
    {"email": "gurmeet.singh@company.com", "password": "Dev@1234"},
    {"email": "abha.sharma@company.com", "password": "Dev@1234"},
    {"email": "harman.preet@company.com", "password": "Dev@1234"},
    {"email": "manjinder.singh@company.com", "password": "Dev@1234"},
    {"email": "lakhveer.singh@company.com", "password": "Dev@1234"},
    {"email": "himanshu.rana@company.com", "password": "Dev@1234"},
    {"email": "akwinder.kaur@company.com", "password": "Dev@1234"},
    {"email": "prince.thakur@company.com", "password": "Dev@1234"},
]


def main():
    """Fix all employee passwords"""
    try:
        print("=" * 70)
        print("🔧 FIXING EMPLOYEE PASSWORDS")
        print("=" * 70)
        print()
        
        # Connect to Supabase
        print("📡 Connecting to Supabase...")
        supabase = create_client(SUPABASE_URL, SUPABASE_KEY)
        print("✅ Connected")
        print()
        
        # Get all profiles
        print("📋 Fetching all profiles...")
        profiles = supabase.table('profiles').select('id, email, full_name').execute()
        
        if not profiles.data:
            print("❌ No profiles found")
            sys.exit(1)
        
        # Create email to user_id map
        email_to_id = {p['email']: p['id'] for p in profiles.data}
        email_to_name = {p['email']: p['full_name'] for p in profiles.data}
        
        print(f"✅ Found {len(profiles.data)} profiles")
        print()
        
        # Update passwords for each employee
        print("=" * 70)
        print("Updating Passwords")
        print("=" * 70)
        
        success_count = 0
        fail_count = 0
        
        for emp in EMPLOYEES:
            email = emp['email']
            password = emp['password']
            
            if email not in email_to_id:
                print(f"⚠️  {email} - Profile not found, skipping")
                fail_count += 1
                continue
            
            user_id = email_to_id[email]
            name = email_to_name[email]
            
            print(f"👤 {name} ({email})")
            
            try:
                # Update user password using admin API
                supabase.auth.admin.update_user_by_id(
                    user_id,
                    {
                        "password": password,
                        "email_confirm": True
                    }
                )
                print(f"   ✅ Password updated: {password}")
                success_count += 1
                
            except Exception as e:
                print(f"   ❌ Failed: {e}")
                fail_count += 1
            
            print()
        
        # Summary
        print("=" * 70)
        print("📊 SUMMARY")
        print("=" * 70)
        print(f"✅ Successfully updated: {success_count}")
        print(f"❌ Failed: {fail_count}")
        print()
        
        if fail_count == 0:
            print("🎉 All passwords updated successfully!")
            print()
            print("Next steps:")
            print("1. Try logging in with any employee credentials")
            print("2. Use the company_id: 01e20568-18c6-4020-a3b3-6c717a023baf")
        else:
            print(f"⚠️  {fail_count} password(s) failed to update")
        
        print("=" * 70)
        
    except Exception as e:
        print(f"❌ Fatal Error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)


if __name__ == "__main__":
    main()
