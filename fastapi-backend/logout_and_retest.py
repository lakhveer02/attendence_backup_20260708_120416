"""
Logout all sessions and retest all employee logins
"""

import asyncio
import sys
import os

sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.database_complete import db_complete as db

COMPANY_ID = "af34c761-300a-404e-9301-6674605bad0a"

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


async def logout_all_sessions():
    """Logout all active sessions"""
    print("\n" + "="*80)
    print("🔓 Logging Out All Sessions")
    print("="*80 + "\n")
    
    try:
        # Sign out from current session if any
        db.client.auth.sign_out()
        print("✅ Cleared local session\n")
    except Exception as e:
        print(f"⚠️  No active session to clear: {e}\n")


async def verify_all_profiles():
    """Verify all profiles exist with direct query (no RLS)"""
    print("\n" + "="*80)
    print("🔍 Step 1: Verifying All Profiles in Database")
    print("="*80 + "\n")
    
    profiles_found = {}
    
    for idx, (name, title, email, password, role) in enumerate(EMPLOYEES, 1):
        try:
            # Direct query without any joins (avoids RLS issues)
            response = db.client.table("profiles").select("*").eq("email", email).execute()
            
            if response.data:
                profile = response.data[0]
                profiles_found[email] = profile
                print(f"✅ [{idx}/12] {name} ({title})")
                print(f"   📧 {email}")
                print(f"   🆔 {profile['id']}")
                print(f"   👔 {profile['role']}")
                print()
            else:
                print(f"❌ [{idx}/12] {name} - NOT FOUND")
                print(f"   📧 {email}")
                print()
        except Exception as e:
            print(f"❌ [{idx}/12] {name} - Error: {str(e)}")
            print()
    
    return profiles_found


async def test_fresh_logins(profiles_found):
    """Test fresh login for each employee"""
    print("\n" + "="*80)
    print("🔐 Step 2: Testing Fresh Login for All Employees")
    print("="*80 + "\n")
    
    success_count = 0
    failed_logins = []
    
    for idx, (name, title, email, password, role) in enumerate(EMPLOYEES, 1):
        if email not in profiles_found:
            print(f"⏭️  [{idx}/12] {name} - Skipped (profile missing)")
            failed_logins.append((name, "Profile not found"))
            print()
            continue
        
        try:
            # Clear any existing session first
            try:
                db.client.auth.sign_out()
            except:
                pass
            
            # Fresh login
            auth_response = db.client.auth.sign_in_with_password({
                "email": email,
                "password": password
            })
            
            if auth_response.user and auth_response.session:
                profile = profiles_found[email]
                
                print(f"✅ [{idx}/12] {name} ({title})")
                print(f"   📧 {email}")
                print(f"   🔑 Password: ✓ Correct")
                print(f"   🆔 Auth ID: {auth_response.user.id}")
                print(f"   🎟️  Session: {auth_response.session.access_token[:30]}...")
                print(f"   👔 Role: {profile['role']}")
                print(f"   ✅ LOGIN SUCCESS")
                print()
                
                success_count += 1
                
                # Sign out after successful test
                db.client.auth.sign_out()
            else:
                print(f"❌ [{idx}/12] {name} - Auth failed (no session)")
                failed_logins.append((name, "No session returned"))
                print()
        except Exception as e:
            error_msg = str(e)
            print(f"❌ [{idx}/12] {name} - Login error")
            print(f"   Error: {error_msg}")
            failed_logins.append((name, error_msg))
            print()
    
    return success_count, failed_logins


async def test_profile_fetch_after_login(profiles_found):
    """Test if we can fetch profile after login (tests RLS)"""
    print("\n" + "="*80)
    print("🧪 Step 3: Testing Profile Fetch After Login (RLS Test)")
    print("="*80 + "\n")
    
    # Test with one employee
    test_email = "chantenbarta@squadminds.com"
    test_password = "Ceo@2024Squad"
    
    try:
        # Login
        auth_response = db.client.auth.sign_in_with_password({
            "email": test_email,
            "password": test_password
        })
        
        if auth_response.user:
            print(f"✅ Logged in as: {test_email}")
            print(f"   Auth ID: {auth_response.user.id}\n")
            
            # Try to fetch own profile (this tests RLS)
            try:
                profile_response = db.client.table("profiles").select("*").eq("email", test_email).execute()
                
                if profile_response.data:
                    print(f"✅ Profile fetch SUCCESSFUL (RLS allows access)")
                    print(f"   Profile ID: {profile_response.data[0]['id']}")
                    print(f"   Full Name: {profile_response.data[0]['full_name']}")
                    print(f"   Role: {profile_response.data[0]['role']}")
                else:
                    print(f"❌ Profile fetch returned EMPTY (RLS blocking access)")
                    print(f"   This means RLS policies are blocking user from reading their own profile")
            except Exception as fetch_error:
                print(f"❌ Profile fetch FAILED with error:")
                print(f"   {str(fetch_error)}")
                
                if "infinite recursion" in str(fetch_error).lower():
                    print(f"\n   🔧 ISSUE: RLS policies have infinite recursion")
                    print(f"   💡 FIX: Run DISABLE_RLS_TEMP.sql in Supabase")
            
            # Logout
            db.client.auth.sign_out()
        else:
            print(f"❌ Login failed for test user")
    except Exception as e:
        print(f"❌ Test failed: {str(e)}")
    
    print()


async def main():
    """Main execution"""
    print("\n" + "="*80)
    print("🔄 LOGOUT ALL & RETEST ALL LOGINS")
    print("="*80)
    print(f"\nCompany: SQUADMINDS PRIVATE LIMITED")
    print(f"Company ID: {COMPANY_ID}")
    print(f"Total Employees: {len(EMPLOYEES)}\n")
    
    # Step 0: Logout
    await logout_all_sessions()
    
    # Step 1: Verify profiles
    profiles_found = await verify_all_profiles()
    
    # Step 2: Test fresh logins
    success_count, failed_logins = await test_fresh_logins(profiles_found)
    
    # Step 3: Test RLS
    await test_profile_fetch_after_login(profiles_found)
    
    # Final Summary
    print("\n" + "="*80)
    print("📊 FINAL TEST RESULTS")
    print("="*80 + "\n")
    
    print(f"👥 Profiles Found: {len(profiles_found)}/12")
    print(f"✅ Successful Logins: {success_count}/12")
    print(f"❌ Failed Logins: {len(failed_logins)}/12")
    
    if failed_logins:
        print(f"\n⚠️  Failed Login Details:")
        for name, error in failed_logins:
            print(f"   - {name}: {error}")
    
    # Status summary
    print("\n" + "="*80)
    print("📋 STATUS SUMMARY")
    print("="*80 + "\n")
    
    if success_count == 12:
        print("🎉 ALL 12 EMPLOYEES CAN LOGIN SUCCESSFULLY!")
        print("✅ All profiles exist")
        print("✅ All passwords work")
        print("✅ Authentication fully functional")
        print("\n💡 Next: Test Flutter app login")
    elif success_count >= 10:
        print(f"✅ {success_count}/12 employees can login ({success_count/12*100:.0f}%)")
        print("⚠️  A few issues remaining")
    else:
        print(f"⚠️  Only {success_count}/12 logins working")
        print("🔧 Issues need to be resolved")
    
    # Credentials reference
    print("\n" + "="*80)
    print("📝 QUICK LOGIN REFERENCE")
    print("="*80 + "\n")
    
    print(f"🏢 Company ID: {COMPANY_ID}\n")
    
    for name, title, email, password, role in EMPLOYEES:
        status = "✅" if email in profiles_found else "❌"
        print(f"{status} {name} ({title})")
        print(f"   📧 {email}")
        print(f"   🔑 {password}")
        print()
    
    print("="*80)
    print("\n💡 TIP: If RLS is blocking, run:")
    print("   SQL: ALTER TABLE profiles DISABLE ROW LEVEL SECURITY;")
    print("   File: fastapi-backend/DISABLE_RLS_TEMP.sql")
    print("\n" + "="*80)


if __name__ == "__main__":
    asyncio.run(main())
