#!/usr/bin/env python3
"""Create a test account for login"""

import requests
import json

BASE_URL = "http://localhost:8000"

def create_super_admin():
    """Create a super admin account"""
    print("\n" + "="*60)
    print("CREATING SUPER ADMIN TEST ACCOUNT")
    print("="*60 + "\n")
    
    payload = {
        "email": "admin@test.com",
        "password": "Admin@1234",
        "full_name": "Test Admin",
        "role": "super_admin",
        "phone_number": "1234567890",
        "create_company": False
    }
    
    print(f"Creating account: {payload['email']}")
    print(f"Password: {payload['password']}\n")
    
    try:
        response = requests.post(
            f"{BASE_URL}/api/v1/auth/signup",
            json=payload
        )
        
        if response.status_code == 201:
            print("✅ Account created successfully!")
            print("\n📝 Login credentials:")
            print(f"   Email: {payload['email']}")
            print(f"   Password: {payload['password']}")
            print("\nYou can now use these credentials to login in the Flutter app!")
        elif response.status_code == 409:
            print("ℹ️  Account already exists!")
            print("\n📝 Login credentials:")
            print(f"   Email: {payload['email']}")
            print(f"   Password: {payload['password']}")
        else:
            print(f"❌ Failed: {response.text}")
    except Exception as e:
        print(f"❌ Error: {e}")
    
    print("\n" + "="*60 + "\n")

if __name__ == "__main__":
    create_super_admin()
