#!/usr/bin/env python3
"""
Test complete authentication flow with role-based access
"""
import requests
import json

BASE_URL = "http://localhost:8000"

def test_login_and_dashboard():
    """Test login and dashboard access"""
    print("=" * 80)
    print("TEST: Login and Dashboard Access")
    print("=" * 80)
    
    # Step 1: Login
    print("\n📝 Step 1: Login")
    print("-" * 80)
    
    login_data = {
        "email": "chetan@squadminds.com",
        "password": "Ceo@7890",
        "device_id": "test-device"
    }
    
    response = requests.post(
        f"{BASE_URL}/api/v1/auth-bypass/login",
        json=login_data,
        headers={"Content-Type": "application/json"}
    )
    
    print(f"Status: {response.status_code}")
    print(f"Response: {json.dumps(response.json(), indent=2)}")
    
    if response.status_code != 200:
        print("❌ Login failed!")
        return
    
    data = response.json()
    access_token = data.get("access_token")
    user = data.get("user", {})
    
    print(f"\n✅ Login successful!")
    print(f"   Email: {user.get('email')}")
    print(f"   Role: {user.get('role')}")
    print(f"   Company ID: {user.get('company_id')}")
    print(f"   Token: {access_token[:50]}..." if access_token else "   Token: None")
    
    if not access_token:
        print("\n⚠️ WARNING: No access token returned!")
        return
    
    # Step 2: Access Dashboard
    print("\n📊 Step 2: Access Dashboard Stats")
    print("-" * 80)
    
    company_id = user.get('company_id')
    headers = {
        "Authorization": f"Bearer {access_token}",
        "Content-Type": "application/json"
    }
    
    response = requests.get(
        f"{BASE_URL}/api/v1/dashboard/stats",
        params={"company_id": company_id} if company_id else {},
        headers=headers
    )
    
    print(f"Status: {response.status_code}")
    
    if response.status_code == 200:
        stats = response.json()
        print(f"\n✅ Dashboard access successful!")
        print(f"   Total Employees: {stats.get('total_employees', 0)}")
        print(f"   Present Today: {stats.get('present_today', 0)}")
    else:
        print(f"\n❌ Dashboard access failed!")
        print(f"Response: {response.text}")
        
        # Try to decode the token to see what's wrong
        print("\n🔍 Debugging token...")
        import jwt
        try:
            decoded = jwt.decode(access_token, options={"verify_signature": False})
            print(f"Token payload: {json.dumps(decoded, indent=2, default=str)}")
        except Exception as e:
            print(f"Could not decode token: {e}")

if __name__ == "__main__":
    test_login_and_dashboard()
