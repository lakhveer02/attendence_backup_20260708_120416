"""
Create comprehensive test users via API signup endpoint
"""
import requests
import json

BASE_URL = "http://localhost:8000/api/v1"

# Test user credentials - SAVE THESE FOR TESTING
TEST_USERS = [
    {
        "email": "superadmin@test.com",
        "password": "Super@123",
        "full_name": "Super Administrator",
        "role": "super_admin",
        "phone_number": "+1234567890",
        "create_company": False,
        "company_id": None
    },
    {
        "email": "admin@beersingh.com",
        "password": "Admin@123",
        "full_name": "Company Admin",
        "role": "company_admin",
        "phone_number": "+1234567891",
        "create_company": False,
        "company_id": "deecce3d-40e1-438e-b12a-900dd4a036c8"  # Existing company
    },
    {
        "email": "hr@beersingh.com",
        "password": "HRManager@123",
        "full_name": "HR Manager",
        "role": "hr_manager",
        "phone_number": "+1234567892",
        "create_company": False,
        "company_id": "deecce3d-40e1-438e-b12a-900dd4a036c8"
    },
    {
        "email": "manager@beersingh.com",
        "password": "Manager@123",
        "full_name": "Manager",
        "role": "manager",
        "phone_number": "+1234567893",
        "create_company": False,
        "company_id": "deecce3d-40e1-438e-b12a-900dd4a036c8"
    },
    {
        "email": "employee@beersingh.com",
        "password": "Employee@123",
        "full_name": "John Employee",
        "role": "employee",
        "phone_number": "+1234567894",
        "create_company": False,
        "company_id": "deecce3d-40e1-438e-b12a-900dd4a036c8"
    }
]


def create_users_via_signup():
    """Create users via API signup endpoint"""
    print("=" * 70)
    print("🔐 CREATING TEST USERS VIA API")
    print("=" * 70)
    
    created_count = 0
    failed_count = 0
    
    for user_data in TEST_USERS:
        print(f"\n📝 Creating {user_data['role'].upper().replace('_', ' ')} user...")
        print(f"   Email: {user_data['email']}")
        
        try:
            response = requests.post(
                f"{BASE_URL}/auth/signup",
                json=user_data,
                headers={"Content-Type": "application/json"}
            )
            
            if response.status_code in [200, 201]:
                print(f"   ✅ Created successfully")
                print(f"   🔑 Password: {user_data['password']}")
                created_count += 1
            elif response.status_code == 400:
                error_data = response.json()
                if "already exists" in str(error_data.get("detail", "")).lower():
                    print(f"   ⚠️  User already exists")
                    print(f"   🔑 Password: {user_data['password']}")
                else:
                    print(f"   ❌ Failed: {error_data.get('detail', 'Unknown error')}")
                    failed_count += 1
            else:
                print(f"   ❌ Failed with status {response.status_code}")
                print(f"   Error: {response.text}")
                failed_count += 1
                
        except Exception as e:
            print(f"   ❌ Exception: {e}")
            failed_count += 1
    
    # Print summary
    print("\n" + "=" * 70)
    print("📊 SUMMARY")
    print("=" * 70)
    print(f"✅ Created: {created_count}")
    print(f"⚠️  Failed: {failed_count}")
    print(f"📋 Total: {len(TEST_USERS)}")
    
    print("\n" + "=" * 70)
    print("📋 LOGIN CREDENTIALS FOR TESTING")
    print("=" * 70)
    
    for user_data in TEST_USERS:
        role_display = user_data['role'].upper().replace('_', ' ')
        print(f"\n┌─ {role_display}")
        print(f"│  Email:    {user_data['email']}")
        print(f"│  Password: {user_data['password']}")
        print(f"│  Role:     {user_data['role']}")
        company_display = user_data.get('company_id', 'None (Super Admin)')
        if company_display and len(company_display) > 30:
            company_display = company_display[:30] + "..."
        print(f"└─ Company:  {company_display}")
    
    print("\n" + "=" * 70)
    print("🧪 TEST LOGIN COMMANDS")
    print("=" * 70)
    
    for user_data in TEST_USERS:
        role_display = user_data['role'].replace('_', ' ').title()
        print(f"\n# {role_display}")
        print(f"curl -X POST {BASE_URL}/auth/login \\")
        print(f"  -H 'Content-Type: application/json' \\")
        print(f"  -d '{{")
        print(f'    "email": "{user_data["email"]}",')
        print(f'    "password": "{user_data["password"]}",')
        print(f'    "device_id": "test-device-123"')
        print(f"  }}'")
    
    print("\n" + "=" * 70)


if __name__ == "__main__":
    create_users_via_signup()
