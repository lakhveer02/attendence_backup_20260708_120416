#!/usr/bin/env python3
"""
Test All Employee Logins with Delay
Tests logins with delay to avoid rate limiting
"""

import requests
import json
import time
from datetime import datetime

# Backend URL
BASE_URL = "http://localhost:8000"

# Company ID
COMPANY_ID = "01e20568-18c6-4020-a3b3-6c717a023baf"

# All employees with credentials
EMPLOYEES = [
    {
        "name": "Chanten Batra (CEO)",
        "email": "chanten.batra@company.com",
        "password": "Ceo@1234",
        "role": "company_admin"
    },
    {
        "name": "Deepak Batra (HR Manager)",
        "email": "deepak.batra@company.com",
        "password": "Hr@1234",
        "role": "hr_manager"
    },
    {
        "name": "Paryanshi (HR Executive)",
        "email": "paryanshi@company.com",
        "password": "Hr@1234",
        "role": "hr_manager"
    },
    {
        "name": "Dev Gangwar (Team Manager)",
        "email": "dev.gangwar@company.com",
        "password": "Manager@1234",
        "role": "manager"
    },
    {
        "name": "Gurmeet Singh (Web Developer)",
        "email": "gurmeet.singh@company.com",
        "password": "Dev@1234",
        "role": "employee"
    },
    {
        "name": "Abha Sharma (React Developer)",
        "email": "abha.sharma@company.com",
        "password": "Dev@1234",
        "role": "employee"
    },
]


def test_login(employee):
    """Test login for a single employee"""
    print(f"\nTesting: {employee['name']}")
    print(f"   Email: {employee['email']}")
    
    login_data = {
        "email": employee['email'],
        "password": employee['password'],
        "company_id": COMPANY_ID,
        "device_id": "test_device_001",
        "device_name": "Test Device",
    }
    
    try:
        response = requests.post(
            f"{BASE_URL}/api/v1/auth/login",
            json=login_data,
            headers={"Content-Type": "application/json"},
            timeout=10
        )
        
        if response.status_code == 200:
            result = response.json()
            user = result.get('user', {})
            print(f"   ✅ LOGIN SUCCESSFUL - {user.get('full_name')} ({user.get('role')})")
            return True
        else:
            print(f"   ❌ LOGIN FAILED - {response.status_code}: {response.text}")
            return False
            
    except Exception as e:
        print(f"   ❌ ERROR: {e}")
        return False


def main():
    """Main test execution"""
    print("=" * 70)
    print("🧪 EMPLOYEE LOGIN TEST (With Delay)")
    print("=" * 70)
    print(f"Testing {len(EMPLOYEES)} employees with 15s delay between tests...")
    print()
    
    # Test employees with delay
    results = []
    for i, employee in enumerate(EMPLOYEES):
        success = test_login(employee)
        results.append(success)
        
        # Add delay between tests (except after last test)
        if i < len(EMPLOYEES) - 1:
            print(f"   ⏳ Waiting 15 seconds to avoid rate limiting...")
            time.sleep(15)
    
    # Summary
    print()
    print("=" * 70)
    successful = sum(results)
    print(f"✅ Successful: {successful}/{len(EMPLOYEES)}")
    print(f"❌ Failed: {len(EMPLOYEES) - successful}/{len(EMPLOYEES)}")
    print("=" * 70)


if __name__ == "__main__":
    main()
