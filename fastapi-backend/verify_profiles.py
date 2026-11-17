"""
Verify all profiles exist in database and test direct queries
"""

import asyncio
import sys
import os

sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.database_complete import db_complete as db

COMPANY_ID = "af34c761-300a-404e-9301-6674605bad0a"

async def verify_profiles():
    """Check all profiles directly"""
    print("\n" + "="*80)
    print("🔍 Verifying All Profiles in Database")
    print("="*80 + "\n")
    
    employees = [
        "chantenbarta@squadminds.com",
        "pryanshi@squadminds.com",
        "deepak.batra@squadminds.com",
        "dev.gangwar@squadminds.com",
        "gurmeet.singh@squadminds.com",
        "abha.sharma@squadminds.com",
        "harman.preet@squadminds.com",
        "manjinder.singh@squadminds.com",
        "lakhveer.singh@squadminds.com",
        "himanshu.rana@squadminds.com",
        "akwinder.kaur@squadminds.com",
        "prince.thakur@squadminds.com",
    ]
    
    for idx, email in enumerate(employees, 1):
        try:
            # Direct table query
            response = db.client.table("profiles").select("*").eq("email", email).execute()
            
            if response.data:
                profile = response.data[0]
                print(f"✅ [{idx}/12] {profile['full_name']}")
                print(f"   📧 Email: {profile['email']}")
                print(f"   🆔 ID: {profile['id']}")
                print(f"   🏢 Company ID: {profile.get('company_id')}")
                print(f"   👔 Role: {profile.get('role')}")
                print(f"   ✓ Active: {profile.get('is_active')}")
                print()
            else:
                print(f"❌ [{idx}/12] {email} - NOT FOUND in database")
                print()
        except Exception as e:
            print(f"❌ [{idx}/12] {email} - Error: {str(e)}")
            print()
    
    # Also check company
    print("="*80)
    print("🏢 Company Verification")
    print("="*80 + "\n")
    
    try:
        company_response = db.client.table("companies").select("*").eq("id", COMPANY_ID).execute()
        
        if company_response.data:
            company = company_response.data[0]
            print(f"✅ Company Found: {company['name']}")
            print(f"   🆔 ID: {company['id']}")
            print(f"   📊 Status: {company.get('status')}")
            print(f"   🌍 Timezone: {company.get('timezone')}")
        else:
            print(f"❌ Company NOT FOUND with ID: {COMPANY_ID}")
    except Exception as e:
        print(f"❌ Error fetching company: {str(e)}")
    
    print("\n" + "="*80)


async def test_login_with_direct_query():
    """Test login using direct profile queries"""
    print("\n" + "="*80)
    print("🧪 Testing Login with Direct Queries")
    print("="*80 + "\n")
    
    test_emails = [
        ("chantenbarta@squadminds.com", "Ceo@2024Squad"),
        ("gurmeet.singh@squadminds.com", "Gurmeet@2024Squad"),
        ("pryanshi@squadminds.com", "Hr@2024Squad"),
    ]
    
    for email, password in test_emails:
        print(f"\n🔐 Testing: {email}")
        print("-" * 40)
        
        try:
            # Step 1: Auth login
            auth_response = db.client.auth.sign_in_with_password({
                "email": email,
                "password": password
            })
            
            if auth_response.user:
                print(f"   ✅ Auth successful")
                print(f"   🆔 Auth User ID: {auth_response.user.id}")
                
                # Step 2: Get profile by ID
                profile_response = db.client.table("profiles").select("*").eq("id", auth_response.user.id).execute()
                
                if profile_response.data:
                    profile = profile_response.data[0]
                    print(f"   ✅ Profile found by ID")
                    print(f"   👤 Name: {profile['full_name']}")
                    print(f"   👔 Role: {profile['role']}")
                    print(f"   🏢 Company: {profile.get('company_id')}")
                else:
                    print(f"   ❌ Profile NOT FOUND by auth user ID")
                    
                    # Try by email
                    profile_response = db.client.table("profiles").select("*").eq("email", email).execute()
                    if profile_response.data:
                        profile = profile_response.data[0]
                        print(f"   ⚠️  Profile found by email but ID mismatch!")
                        print(f"   Profile ID: {profile['id']}")
                        print(f"   Auth User ID: {auth_response.user.id}")
                    else:
                        print(f"   ❌ Profile also NOT FOUND by email")
            else:
                print(f"   ❌ Auth failed")
                
        except Exception as e:
            print(f"   ❌ Error: {str(e)}")
    
    print("\n" + "="*80)


if __name__ == "__main__":
    asyncio.run(verify_profiles())
    asyncio.run(test_login_with_direct_query())
