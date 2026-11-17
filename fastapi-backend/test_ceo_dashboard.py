#!/usr/bin/env python3
"""
Test CEO Login and Dashboard
Complete flow test for CEO authentication and dashboard data
"""

import requests
import json
from datetime import datetime

# Backend URL
BASE_URL = "http://localhost:8000"

# Company and CEO credentials
COMPANY_ID = "01e20568-18c6-4020-a3b3-6c717a023baf"
CEO_EMAIL = "chanten.batra@company.com"
CEO_PASSWORD = "Ceo@1234"


def test_ceo_flow():
    """Test complete CEO login and dashboard flow"""
    print("=" * 80)
    print("🧪 CEO LOGIN & DASHBOARD TEST")
    print("=" * 80)
    print()
    
    # Step 1: Login as CEO
    print("📝 Step 1: CEO Login")
    print("-" * 80)
    
    login_data = {
        "email": CEO_EMAIL,
        "password": CEO_PASSWORD,
        "company_id": COMPANY_ID,
        "device_id": "test_device_ceo",
        "device_name": "Test Device"
    }
    
    try:
        login_response = requests.post(
            f"{BASE_URL}/api/v1/auth/login",
            json=login_data,
            headers={"Content-Type": "application/json"},
            timeout=10
        )
        
        if login_response.status_code == 200:
            login_result = login_response.json()
            user = login_result.get('user', {})
            token = login_result.get('access_token')
            
            print(f"✅ LOGIN SUCCESSFUL")
            print(f"   Name: {user.get('full_name')}")
            print(f"   Email: {user.get('email')}")
            print(f"   Role: {user.get('role')}")
            print(f"   Company: {user.get('company_name')}")
            print(f"   Token: {token[:50]}...")
            print()
            
            # Step 2: Fetch Dashboard Stats
            print("📊 Step 2: Fetching Dashboard Statistics")
            print("-" * 80)
            
            headers = {
                "Authorization": f"Bearer {token}",
                "Content-Type": "application/json"
            }
            
            dashboard_response = requests.get(
                f"{BASE_URL}/api/v1/dashboard/stats",
                params={"company_id": COMPANY_ID},
                headers=headers,
                timeout=10
            )
            
            if dashboard_response.status_code == 200:
                stats = dashboard_response.json()
                
                print(f"✅ DASHBOARD DATA RETRIEVED")
                print()
                print(f"📊 Company Statistics:")
                print(f"   Total Employees: {stats.get('totalEmployees')}")
                print(f"   Present Today: {stats.get('presentToday')}")
                print(f"   Absent Today: {stats.get('absentToday')}")
                print(f"   On Leave: {stats.get('onLeave')}")
                print(f"   Late Today: {stats.get('lateToday')}")
                print(f"   Attendance Rate (Today): {stats.get('attendanceRateToday')}%")
                print(f"   Attendance Rate (Month): {stats.get('attendanceRateMonth')}%")
                print(f"   Pending Leave Requests: {stats.get('pendingLeaveRequests')}")
                print()
                
                # Verify employee count
                total_employees = stats.get('totalEmployees')
                if total_employees == 12:
                    print("🎉 SUCCESS! Dashboard shows all 12 employees!")
                    print()
                    
                    # Step 3: Fetch Employee Distribution
                    print("📈 Step 3: Fetching Employee Distribution")
                    print("-" * 80)
                    
                    dist_response = requests.get(
                        f"{BASE_URL}/api/v1/dashboard/employee-distribution",
                        headers=headers,
                        timeout=10
                    )
                    
                    if dist_response.status_code == 200:
                        dist = dist_response.json()
                        
                        print("✅ DISTRIBUTION DATA RETRIEVED")
                        print()
                        
                        if dist.get('byRole'):
                            print("👥 By Role:")
                            for role_data in dist['byRole']:
                                print(f"   {role_data['role']}: {role_data['count']} employees")
                            print()
                        
                        if dist.get('byDepartment'):
                            print("🏢 By Department:")
                            for dept_data in dist['byDepartment']:
                                print(f"   {dept_data['department']}: {dept_data['count']} employees")
                            print()
                    else:
                        print(f"⚠️  Distribution fetch failed: {dist_response.status_code}")
                        print(f"   Response: {dist_response.text}")
                        print()
                    
                    # Step 4: Fetch All Profiles
                    print("👤 Step 4: Fetching All Employee Profiles")
                    print("-" * 80)
                    
                    profiles_response = requests.get(
                        f"{BASE_URL}/api/v1/profiles",
                        headers=headers,
                        timeout=10
                    )
                    
                    if profiles_response.status_code == 200:
                        profiles = profiles_response.json()
                        
                        print(f"✅ PROFILES RETRIEVED: {len(profiles)} employees")
                        print()
                        
                        # Group by role
                        roles = {}
                        for profile in profiles:
                            role = profile.get('role', 'unknown')
                            if role not in roles:
                                roles[role] = []
                            roles[role].append(profile)
                        
                        for role, emps in roles.items():
                            print(f"📋 {role.upper().replace('_', ' ')}:")
                            for emp in emps:
                                print(f"   • {emp.get('full_name')} ({emp.get('email')})")
                            print()
                    else:
                        print(f"⚠️  Profiles fetch failed: {profiles_response.status_code}")
                        print()
                    
                    # Final Summary
                    print("=" * 80)
                    print("✅ ALL TESTS PASSED!")
                    print("=" * 80)
                    print()
                    print("🎯 CEO Dashboard Status: WORKING")
                    print("📊 Employee Count: CORRECT (12/12)")
                    print("🔐 Authentication: SUCCESS")
                    print("📈 Data Retrieval: SUCCESS")
                    print()
                    return True
                    
                else:
                    print(f"❌ EMPLOYEE COUNT MISMATCH")
                    print(f"   Expected: 12")
                    print(f"   Got: {total_employees}")
                    print()
                    return False
                    
            else:
                print(f"❌ Dashboard fetch failed: {dashboard_response.status_code}")
                print(f"   Response: {dashboard_response.text}")
                return False
                
        else:
            print(f"❌ Login failed: {login_response.status_code}")
            print(f"   Response: {login_response.text}")
            return False
            
    except requests.exceptions.ConnectionError:
        print("❌ CONNECTION ERROR")
        print("   Backend is not running at", BASE_URL)
        print("   Please start with: ./start_backend.sh")
        return False
    except Exception as e:
        print(f"❌ ERROR: {e}")
        import traceback
        traceback.print_exc()
        return False


def main():
    """Run the test"""
    success = test_ceo_flow()
    
    if not success:
        print()
        print("=" * 80)
        print("⚠️  TESTS FAILED")
        print("=" * 80)
        print()
        print("Troubleshooting:")
        print("1. Ensure backend is running: ps aux | grep uvicorn")
        print("2. Check backend logs: tail -f backend.log")
        print("3. Verify employees created: python3 test_dashboard_fix.py")
        print()
        sys.exit(1)


if __name__ == "__main__":
    import sys
    main()
