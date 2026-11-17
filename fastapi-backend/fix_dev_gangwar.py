"""
Fix Dev Gangwar's account - Create with 'employee' role since 'team_manager' is not in DB enum
Then test all employee logins
"""

import asyncio
import sys
import os

sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.database_complete import db_complete as db
from app.auth.jwt_handler import jwt_handler

COMPANY_ID = "af34c761-300a-404e-9301-6674605bad0a"

async def fix_dev_gangwar():
    """Create Dev Gangwar with employee role"""
    print("\n" + "="*80)
    print("🔧 Fixing Dev Gangwar Account")
    print("="*80 + "\n")
    
    emp = {
        "full_name": "Dev Gangwar",
        "email": "dev.gangwar@squadminds.com",
        "phone_number": "+91-9876543213",
        "role": "employee",  # Changed from team_manager to employee
        "designation": "Team Manager",
        "password": "Dev@2024Squad",
    }
    
    try:
        # Check if already exists
        existing = await db.execute_query(
            "SELECT id, email FROM profiles WHERE email = $1 AND company_id = $2",
            emp["email"],
            COMPANY_ID
        )
        
        if existing:
            print(f"✅ Dev Gangwar already exists with ID: {existing[0]['id']}")
            return existing[0]['id']
        
        # Create Supabase Auth user
        try:
            auth_response = db.client.auth.admin.create_user({
                "email": emp["email"],
                "password": emp["password"],
                "email_confirm": True,
                "user_metadata": {
                    "full_name": emp["full_name"],
                    "role": emp["role"]
                }
            })
            
            auth_user_id = auth_response.user.id
            print(f"✅ Auth user created: {auth_user_id}")
        except Exception as auth_error:
            print(f"❌ Auth creation failed: {auth_error}")
            return None
        
        # Create profile
        profile_data = {
            "id": auth_user_id,
            "company_id": COMPANY_ID,
            "workspace_id": COMPANY_ID,
            "email": emp["email"],
            "full_name": emp["full_name"],
            "phone_number": emp["phone_number"],
            "role": emp["role"],
            "is_active": True
        }
        
        profile = await db.create_profile(profile_data)
        print(f"✅ Profile created: {profile['id']}")
        print(f"   📧 Email: {emp['email']}")
        print(f"   🔑 Password: {emp['password']}")
        print(f"   👔 Role: {emp['role']} (functioning as Team Manager)")
        
        return profile['id']
        
    except Exception as e:
        print(f"❌ Failed to create Dev Gangwar: {str(e)}")
        return None


async def test_all_logins():
    """Test login for all employees"""
    print("\n" + "="*80)
    print("🧪 Testing All Employee Logins")
    print("="*80 + "\n")
    
    employees = [
        ("Chantenbarta (CEO)", "chantenbarta@squadminds.com", "Ceo@2024Squad"),
        ("Pryanshi (HR Manager)", "pryanshi@squadminds.com", "Hr@2024Squad"),
        ("Deepak Batra (HR)", "deepak.batra@squadminds.com", "Deepak@2024Squad"),
        ("Dev Gangwar (Team Manager)", "dev.gangwar@squadminds.com", "Dev@2024Squad"),
        ("Gurmeet Singh", "gurmeet.singh@squadminds.com", "Gurmeet@2024Squad"),
        ("Abha Sharma", "abha.sharma@squadminds.com", "Abha@2024Squad"),
        ("Harman Preet", "harman.preet@squadminds.com", "Harman@2024Squad"),
        ("Manjinder Singh", "manjinder.singh@squadminds.com", "Manjinder@2024Squad"),
        ("Lakhveer Singh", "lakhveer.singh@squadminds.com", "Lakhveer@2024Squad"),
        ("Himanshu Rana", "himanshu.rana@squadminds.com", "Himanshu@2024Squad"),
        ("Akwinder Kaur", "akwinder.kaur@squadminds.com", "Akwinder@2024Squad"),
        ("Prince Thakur", "prince.thakur@squadminds.com", "Prince@2024Squad"),
    ]
    
    success_count = 0
    failed_logins = []
    
    for idx, (name, email, password) in enumerate(employees, 1):
        try:
            # Test Supabase Auth login
            auth_response = db.client.auth.sign_in_with_password({
                "email": email,
                "password": password
            })
            
            if auth_response.user:
                # Get profile info
                profile = await db.get_profile_by_email(email)
                
                if profile:
                    print(f"✅ [{idx}/12] {name}")
                    print(f"   📧 {email}")
                    print(f"   👔 Role: {profile['role']}")
                    print(f"   🆔 ID: {profile['id']}")
                    print()
                    success_count += 1
                else:
                    print(f"⚠️  [{idx}/12] {name} - Auth OK, but profile not found")
                    failed_logins.append((name, "Profile not found"))
                    print()
            else:
                print(f"❌ [{idx}/12] {name} - Auth failed")
                failed_logins.append((name, "Auth failed"))
                print()
                
        except Exception as e:
            print(f"❌ [{idx}/12] {name} - Login error: {str(e)}")
            failed_logins.append((name, str(e)))
            print()
    
    # Summary
    print("="*80)
    print("📊 LOGIN TEST SUMMARY")
    print("="*80)
    print(f"\n✅ Successful Logins: {success_count}/12")
    print(f"❌ Failed Logins: {len(failed_logins)}/12")
    
    if failed_logins:
        print("\n⚠️  Failed Login Details:")
        for name, error in failed_logins:
            print(f"   - {name}: {error}")
    else:
        print("\n🎉 All logins successful!")
    
    print("\n" + "="*80)


async def main():
    """Main execution"""
    # Fix Dev Gangwar
    dev_id = await fix_dev_gangwar()
    
    # Test all logins
    await test_all_logins()
    
    # Print final credentials
    print("\n" + "="*80)
    print("📝 COMPLETE LOGIN CREDENTIALS")
    print("="*80)
    print(f"\n🏢 Company ID: {COMPANY_ID}\n")
    
    employees = [
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
    
    for name, title, email, password, role in employees:
        print(f"👤 {name} ({title})")
        print(f"   📧 Email: {email}")
        print(f"   🔑 Password: {password}")
        print(f"   👔 Role: {role}")
        print()
    
    print("="*80)
    print("✅ Setup and Testing Complete!")
    print("="*80)


if __name__ == "__main__":
    asyncio.run(main())
