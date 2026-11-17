"""
Create comprehensive test users for all roles
This script creates dummy users with known passwords for testing
"""
import asyncio
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))

from app.database_complete import db_complete as db
from app.auth.jwt_handler import jwt_handler

# Test user credentials - SAVE THESE FOR TESTING
TEST_USERS = {
    "super_admin": {
        "email": "superadmin@test.com",
        "password": "Super@123",
        "full_name": "Super Administrator",
        "role": "super_admin",
        "phone_number": "+1234567890",
        "company_id": None  # Super admin has no company
    },
    "company_admin": {
        "email": "admin@beersingh.com",
        "password": "Admin@123",
        "full_name": "Company Admin",
        "role": "company_admin",
        "phone_number": "+1234567891",
        "company_id": None  # Will be set to existing company
    },
    "hr_manager": {
        "email": "hr@beersingh.com",
        "password": "HRManager@123",
        "full_name": "HR Manager",
        "role": "hr_manager",
        "phone_number": "+1234567892",
        "company_id": None
    },
    "team_manager": {
        "email": "manager@beersingh.com",
        "password": "Manager@123",
        "full_name": "Team Manager",
        "role": "team_manager",
        "phone_number": "+1234567893",
        "company_id": None
    },
    "employee": {
        "email": "employee@beersingh.com",
        "password": "Employee@123",
        "full_name": "John Employee",
        "role": "employee",
        "phone_number": "+1234567894",
        "company_id": None
    }
}


async def create_test_users():
    """Create all test users"""
    print("=" * 70)
    print("🔐 CREATING TEST USERS FOR ALL ROLES")
    print("=" * 70)
    
    try:
        # Get existing company
        companies = await db.get_all_companies()
        if not companies:
            print("❌ No companies found. Creating demo company...")
            company = await db.create_company({
                "name": "Demo Company",
                "industry": "Technology",
                "size": "small",
                "status": "active",
                "timezone": "UTC"
            })
            company_id = company["id"]
            print(f"✅ Created demo company: {company_id}")
        else:
            company_id = companies[0]["id"]
            print(f"✅ Using existing company: {companies[0]['name']} ({company_id})")
        
        # Update company_id for non-super-admin users
        for role, user_data in TEST_USERS.items():
            if role != "super_admin":
                user_data["company_id"] = company_id
        
        print("\n" + "=" * 70)
        print("Creating users...")
        print("=" * 70)
        
        created_users = []
        
        for role, user_data in TEST_USERS.items():
            print(f"\n📝 Creating {role.upper()} user...")
            
            # Check if user already exists
            existing = await db.get_profile_by_email(user_data["email"])
            if existing:
                print(f"   ⚠️  User already exists: {user_data['email']}")
                print(f"   📧 Email: {user_data['email']}")
                print(f"   🔑 Password: {user_data['password']}")
                created_users.append(user_data)
                continue
            
            # Hash password
            hashed_password = jwt_handler.hash_password(user_data["password"])
            
            # Create profile
            profile_data = {
                "email": user_data["email"],
                "full_name": user_data["full_name"],
                "role": user_data["role"],
                "phone_number": user_data["phone_number"],
                "company_id": user_data["company_id"],
                "hashed_password": hashed_password,
                "is_active": True,
                "is_verified": True
            }
            
            try:
                profile = await db.create_profile(profile_data)
                print(f"   ✅ Created: {user_data['email']}")
                print(f"   📧 Email: {user_data['email']}")
                print(f"   🔑 Password: {user_data['password']}")
                print(f"   👤 Role: {user_data['role']}")
                print(f"   🏢 Company: {user_data['company_id'] or 'None (Super Admin)'}")
                created_users.append(user_data)
            except Exception as e:
                print(f"   ❌ Failed to create {role}: {e}")
        
        # Print summary
        print("\n" + "=" * 70)
        print("✅ TEST USERS CREATED SUCCESSFULLY")
        print("=" * 70)
        print("\n📋 LOGIN CREDENTIALS FOR TESTING:\n")
        
        for role, user_data in TEST_USERS.items():
            print(f"┌─ {role.upper().replace('_', ' ')}")
            print(f"│  Email:    {user_data['email']}")
            print(f"│  Password: {user_data['password']}")
            print(f"│  Role:     {user_data['role']}")
            print(f"└─ Company:  {user_data.get('company_id', 'None (Super Admin)')}\n")
        
        print("=" * 70)
        print("💡 USAGE INSTRUCTIONS:")
        print("=" * 70)
        print("1. Use these credentials in your Flutter app login screen")
        print("2. Each role has different permissions:")
        print("   - Super Admin: Full system access, manage all companies")
        print("   - Company Admin: Manage company users, attendance, leaves")
        print("   - HR Manager: Manage employees, approve leaves")
        print("   - Team Manager: View team attendance, approve team leaves")
        print("   - Employee: Mark attendance, apply for leaves")
        print("\n3. Test login from Flutter app or use curl:")
        print("   curl -X POST http://localhost:8000/api/v1/auth/login \\")
        print("     -H 'Content-Type: application/json' \\")
        print("     -d '{")
        print('       "email": "employee@beersingh.com",')
        print('       "password": "Employee@123",')
        print('       "device_id": "test-device-123"')
        print("     }'")
        print("=" * 70)
        
        return True
        
    except Exception as e:
        print(f"\n❌ Error creating test users: {e}")
        import traceback
        traceback.print_exc()
        return False


if __name__ == "__main__":
    success = asyncio.run(create_test_users())
    sys.exit(0 if success else 1)
