"""
Test all SQUADMINDS employee logins
Uses backend login endpoint to properly test authentication
"""

import asyncio
import sys
import os
import requests
import json

sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.database_complete import db_complete as db

COMPANY_ID = "af34c761-300a-404e-9301-6674605bad0a"

# Check if backend is running
BACKEND_URL = "http://localhost:8000"

EMPLOYEES = [
    ("Chantenbarta", "CEO", "chantenbarta@squadminds.com", "Ceo@2024Squad", "company_admin"),
    ("Pryanshi", "HR Manager", "pryanshi@squadminds.com", "Hr@2024Squad", "hr_manager"),
    ("Deepak Batra", "HR", "deepak.batra@squadminds.com", "Deepak@2024Squad", "hr_manager"),
    ("Dev Gangwar", "Team Manager", "dev.gangwar@squadminds.com", "Dev@2024Squad", "employee"),
    ("Gurmeet Singh", "Web Developer", "gurmeet.singh@squadminds.com", "Gurmeet@2024Squad", "employee"),
    ("Abha Sharma", "React Developer", "abha.sharma@squadminds.com", "Abha@2024Squad", "employee"),
    ("Harman Preet", "React Developer", "harman.preet@squadminds.com", "Harman@2024Squad", "employee"),
    ("Manjinder Singh", "Software Developer", "manjinder.singh@squadminds.com", "Manjinder@2024Squad", "employee"),
    ("Lakhveer Singh", "Mobile App Developer", "lakhveer.singh@squadminds.com", "Lakhveer@2024Squad", "employee"),
    ("Himanshu Rana", "React Native Developer", "himanshu.rana@squadminds.com", "Himanshu@2024Squad", "employee"),
    ("Akwinder Kaur", "Ex Intern", "akwinder.kaur@squadminds.com", "Akwinder@2024Squad", "employee"),
    ("Prince Thakur", "React Native Developer", "prince.thakur@squadminds.com", "Prince@2024Squad", "employee"),
]


async def verify_all_profiles_exist():
    """Verify all profiles exist in database using service key"""
    print("\n" + "="*80)
    print("🔍 Step 1: Verifying All Profiles Exist in Database")
    print("="*80 + "\n")
    
    existing_profiles = {}
    
    for idx, (name, title, email, password, role) in enumerate(EMPLOYEES, 1):
        try:
            response = db.client.table("profiles").select("*").eq("email", email).execute()
            
            if response.data:
                profile = response.data[0]
                existing_profiles[email] = profile
                print(f"✅ [{idx}/12] {name} ({title})")
                print(f"   📧 {email}")
                print(f"   🆔 {profile['id']}")
                print(f"   👔 {profile['role']}")
                print()
            else:
                print(f"❌ [{idx}/12] {name} - Profile NOT FOUND")
                print(f"   📧 {email}")
                print()
        except Exception as e:
            print(f"❌ [{idx}/12] {name} - Error: {str(e)}")
            print()
    
    return existing_profiles


async def test_direct_auth_logins(existing_profiles):
    """Test Supabase Auth login (without backend)"""
    print("\n" + "="*80)
    print("🔐 Step 2: Testing Direct Supabase Auth Login")
    print("="*80 + "\n")
    
    success_count = 0
    failed_logins = []
    
    for idx, (name, title, email, password, role) in enumerate(EMPLOYEES, 1):
        if email not in existing_profiles:
            print(f"⏭️  [{idx}/12] {name} - Skipped (profile doesn't exist)")
            failed_logins.append((name, "Profile not found in database"))
            print()
            continue
        
        try:
            # Test auth login
            auth_response = db.client.auth.sign_in_with_password({
                "email": email,
                "password": password
            })
            
            if auth_response.user:
                profile = existing_profiles[email]
                print(f"✅ [{idx}/12] {name} ({title})")
                print(f"   📧 {email}")
                print(f"   🔑 Password: ✓ Correct")
                print(f"   🆔 Auth ID: {auth_response.user.id}")
                print(f"   👔 Role: {profile['role']}")
                print()
                success_count += 1
            else:
                print(f"❌ [{idx}/12] {name} - Auth failed")
                failed_logins.append((name, "Auth returned no user"))
                print()
        except Exception as e:
            print(f"❌ [{idx}/12] {name} - Error: {str(e)}")
            failed_logins.append((name, str(e)))
            print()
    
    return success_count, failed_logins


async def test_backend_api_logins():
    """Test login via backend API endpoint"""
    print("\n" + "="*80)
    print("🌐 Step 3: Testing Backend API Login Endpoint")
    print("="*80 + "\n")
    
    # Check if backend is running
    try:
        health_response = requests.get(f"{BACKEND_URL}/monitoring/health", timeout=5)
        if health_response.status_code != 200:
            print("⚠️  Backend is not running. Start it with:")
            print("   cd fastapi-backend && uvicorn app.main:app --reload\n")
            return 0, []
    except Exception as e:
        print("⚠️  Backend is not running. Start it with:")
        print("   cd fastapi-backend && uvicorn app.main:app --reload\n")
        return 0, []
    
    print("✅ Backend is running\n")
    
    success_count = 0
    failed_logins = []
    
    for idx, (name, title, email, password, role) in enumerate(EMPLOYEES, 1):
        try:
            login_data = {
                "email": email,
                "password": password,
                "company_id": COMPANY_ID,
                "device_id": "test-device-" + str(idx)
            }
            
            response = requests.post(
                f"{BACKEND_URL}/api/v1/auth/login",
                json=login_data,
                timeout=10
            )
            
            if response.status_code == 200:
                data = response.json()
                print(f"✅ [{idx}/12] {name} ({title})")
                print(f"   📧 {email}")
                print(f"   🎟️  Access Token: {data['access_token'][:50]}...")
                print(f"   👤 User: {data['user']['full_name']}")
                print(f"   👔 Role: {data['user']['role']}")
                print()
                success_count += 1
            else:
                print(f"❌ [{idx}/12] {name} - Login failed")
                print(f"   Status: {response.status_code}")
                print(f"   Error: {response.text}")
                failed_logins.append((name, f"HTTP {response.status_code}"))
                print()
        except Exception as e:
            print(f"❌ [{idx}/12] {name} - Error: {str(e)}")
            failed_logins.append((name, str(e)))
            print()
    
    return success_count, failed_logins


async def main():
    """Main test execution"""
    print("\n" + "="*80)
    print("🏢 SQUADMINDS PRIVATE LIMITED - Complete Login Test")
    print("="*80)
    print(f"\nCompany ID: {COMPANY_ID}")
    print(f"Total Employees: {len(EMPLOYEES)}")
    
    # Step 1: Verify profiles exist
    existing_profiles = await verify_all_profiles_exist()
    
    # Step 2: Test direct auth
    auth_success, auth_failed = await test_direct_auth_logins(existing_profiles)
    
    # Step 3: Test backend API
    api_success, api_failed = await test_backend_api_logins()
    
    # Final Summary
    print("\n" + "="*80)
    print("📊 FINAL TEST SUMMARY")
    print("="*80 + "\n")
    
    print(f"👥 Profiles in Database: {len(existing_profiles)}/12")
    print(f"🔐 Supabase Auth Success: {auth_success}/12")
    print(f"🌐 Backend API Success: {api_success}/12")
    
    if auth_failed:
        print(f"\n⚠️  Auth Login Issues ({len(auth_failed)}):")
        for name, error in auth_failed:
            print(f"   - {name}: {error}")
    
    if api_failed and api_success > 0:
        print(f"\n⚠️  API Login Issues ({len(api_failed)}):")
        for name, error in api_failed:
            print(f"   - {name}: {error}")
    
    # Print credentials summary
    print("\n" + "="*80)
    print("📝 QUICK LOGIN REFERENCE")
    print("="*80 + "\n")
    
    print(f"🏢 Company ID: {COMPANY_ID}\n")
    
    for name, title, email, password, role in EMPLOYEES:
        status = "✅" if email in existing_profiles else "❌"
        print(f"{status} {name} ({title})")
        print(f"   📧 {email}")
        print(f"   🔑 {password}")
        print(f"   👔 {role}")
        print()
    
    print("="*80)
    
    if len(existing_profiles) == 12 and auth_success == 12:
        print("🎉 All employees can log in successfully!")
    elif len(existing_profiles) < 12:
        print("⚠️  Some profiles are missing from the database")
    elif auth_success < len(existing_profiles):
        print("⚠️  Some profiles exist but authentication is failing")
        print("💡 This may be due to RLS policies. Check RLS_FIX_GUIDE.md")
    
    print("="*80 + "\n")


if __name__ == "__main__":
    asyncio.run(main())
