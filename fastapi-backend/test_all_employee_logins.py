"""
Test All Employee Logins
Tests that all 12 employees can login successfully
"""

import httpx
import asyncio
from typing import Dict, List

# Backend URL
BASE_URL = "http://localhost:8000"

# All employees with their credentials
EMPLOYEES = [
    {
        "name": "Chanten Batra",
        "email": "chanten.batra@company.com",
        "password": "Ceo@1234",
        "role": "company_admin",
        "title": "CEO"
    },
    {
        "name": "Deepak Batra",
        "email": "deepak.batra@company.com",
        "password": "Hr@1234",
        "role": "hr_manager",
        "title": "HR"
    },
    {
        "name": "Paryanshi",
        "email": "paryanshi@company.com",
        "password": "Hr@1234",
        "role": "hr_manager",
        "title": "HR"
    },
    {
        "name": "Dev Gangwar",
        "email": "dev.gangwar@company.com",
        "password": "Manager@1234",
        "role": "manager",
        "title": "Team Manager"
    },
    {
        "name": "Gurmeet Singh",
        "email": "gurmeet.singh@company.com",
        "password": "Dev@1234",
        "role": "employee",
        "title": "Web Developer"
    },
    {
        "name": "Abha Sharma",
        "email": "abha.sharma@company.com",
        "password": "Dev@1234",
        "role": "employee",
        "title": "React Developer"
    },
    {
        "name": "Harman Preet",
        "email": "harman.preet@company.com",
        "password": "Dev@1234",
        "role": "employee",
        "title": "React Developer"
    },
    {
        "name": "Manjinder Singh",
        "email": "manjinder.singh@company.com",
        "password": "Dev@1234",
        "role": "employee",
        "title": "Software Developer"
    },
    {
        "name": "Lakhveer Singh",
        "email": "lakhveer.singh@company.com",
        "password": "Dev@1234",
        "role": "employee",
        "title": "Mobile Application Developer"
    },
    {
        "name": "Himanshu Rana",
        "email": "himanshu.rana@company.com",
        "password": "Dev@1234",
        "role": "employee",
        "title": "React Native Developer"
    },
    {
        "name": "Akwinder Kaur",
        "email": "akwinder.kaur@company.com",
        "password": "Dev@1234",
        "role": "employee",
        "title": "Ex Intern (Web Development)"
    },
    {
        "name": "Prince Thakur",
        "email": "prince.thakur@company.com",
        "password": "Dev@1234",
        "role": "employee",
        "title": "React Native Developer"
    }
]

async def test_login(employee: Dict) -> Dict:
    """Test login for a single employee"""
    try:
        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.post(
                f"{BASE_URL}/api/v1/auth/login",
                json={
                    "email": employee["email"],
                    "password": employee["password"]
                }
            )
            
            if response.status_code == 200:
                data = response.json()
                return {
                    "success": True,
                    "name": employee["name"],
                    "email": employee["email"],
                    "role": employee["role"],
                    "expected_role": employee["role"],
                    "title": employee["title"],
                    "token": data.get("access_token", "")[:20] + "...",
                    "profile_id": data.get("profile", {}).get("id", "")[:8]
                }
            else:
                return {
                    "success": False,
                    "name": employee["name"],
                    "email": employee["email"],
                    "error": response.text,
                    "status_code": response.status_code
                }
    except Exception as e:
        return {
            "success": False,
            "name": employee["name"],
            "email": employee["email"],
            "error": str(e)
        }

async def test_all_logins():
    """Test all employee logins"""
    print("=" * 80)
    print("TESTING ALL EMPLOYEE LOGINS")
    print("=" * 80)
    print()
    
    # Test all logins concurrently
    tasks = [test_login(emp) for emp in EMPLOYEES]
    results = await asyncio.gather(*tasks)
    
    # Print results
    successful = []
    failed = []
    
    for result in results:
        if result["success"]:
            successful.append(result)
            print(f"✅ {result['name']} ({result['title']})")
            print(f"   Email: {result['email']}")
            print(f"   Role: {result['role']}")
            print(f"   Profile ID: {result['profile_id']}")
            print()
        else:
            failed.append(result)
            print(f"❌ {result['name']} - FAILED")
            print(f"   Email: {result['email']}")
            print(f"   Error: {result.get('error', 'Unknown error')}")
            print()
    
    # Summary
    print("=" * 80)
    print("SUMMARY")
    print("=" * 80)
    print(f"✅ Successful Logins: {len(successful)}/12")
    print(f"❌ Failed Logins: {len(failed)}/12")
    print()
    
    if len(successful) == 12:
        print("🎉 PERFECT! All 12 employees can login successfully!")
        print()
        print("Breakdown by role:")
        print(f"  - CEO: 1")
        print(f"  - HR Managers: 2")
        print(f"  - Team Manager: 1")
        print(f"  - Developers: 8")
    else:
        print("⚠️  Some logins failed. Check errors above.")
    
    print()
    print("=" * 80)
    
    return len(successful) == 12

async def test_dashboard():
    """Test dashboard stats after login"""
    print("\n" + "=" * 80)
    print("TESTING CEO DASHBOARD")
    print("=" * 80)
    
    try:
        # Login as CEO first
        async with httpx.AsyncClient(timeout=30.0) as client:
            login_response = await client.post(
                f"{BASE_URL}/api/v1/auth/login",
                json={
                    "email": "chanten.batra@company.com",
                    "password": "Ceo@1234"
                }
            )
            
            if login_response.status_code != 200:
                print("❌ CEO login failed!")
                return False
            
            token = login_response.json()["access_token"]
            company_id = login_response.json()["profile"]["company_id"]
            
            # Get dashboard stats
            dashboard_response = await client.get(
                f"{BASE_URL}/api/v1/dashboard/stats?company_id={company_id}",
                headers={"Authorization": f"Bearer {token}"}
            )
            
            if dashboard_response.status_code == 200:
                stats = dashboard_response.json()
                print(f"\n✅ Dashboard Stats Retrieved:")
                print(f"   Total Employees: {stats.get('totalEmployees', 0)}")
                print(f"   Present Today: {stats.get('presentToday', 0)}")
                print(f"   Absent Today: {stats.get('absentToday', 0)}")
                print(f"   On Leave: {stats.get('onLeave', 0)}")
                print(f"   Attendance Rate (Today): {stats.get('attendanceRateToday', 0)}%")
                print()
                
                if stats.get('totalEmployees') == 12:
                    print("✅ PERFECT! Dashboard shows 12 employees")
                    return True
                else:
                    print(f"❌ Dashboard shows {stats.get('totalEmployees', 0)} employees (expected 12)")
                    print("   This means the RLS permission issue is NOT fixed yet.")
                    print("   Run the SQL from FIX_RLS_PERMISSIONS.sql in Supabase SQL Editor")
                    return False
            else:
                print(f"❌ Dashboard request failed: {dashboard_response.status_code}")
                print(dashboard_response.text)
                return False
                
    except Exception as e:
        print(f"❌ Dashboard test error: {e}")
        return False

async def main():
    """Main test function"""
    print("\n🚀 Starting comprehensive employee login tests...\n")
    
    # Test all logins
    all_success = await test_all_logins()
    
    # Test dashboard
    dashboard_success = await test_dashboard()
    
    # Final verdict
    print("\n" + "=" * 80)
    print("FINAL VERDICT")
    print("=" * 80)
    
    if all_success and dashboard_success:
        print("🎉 ALL TESTS PASSED!")
        print("✅ All 12 employees can login")
        print("✅ Dashboard shows correct employee count")
        print("\nYour attendance system is ready to use!")
    elif all_success:
        print("⚠️  PARTIAL SUCCESS")
        print("✅ All 12 employees can login")
        print("❌ Dashboard employee count is incorrect")
        print("\n📝 Next Step: Fix RLS permissions using FIX_RLS_PERMISSIONS.sql")
    else:
        print("❌ TESTS FAILED")
        print("Some employees cannot login or dashboard is not working")
        print("\n📝 Check PERMISSION_ISSUE_FIX.md for troubleshooting")
    
    print("=" * 80 + "\n")
    
    return all_success and dashboard_success

if __name__ == "__main__":
    try:
        success = asyncio.run(main())
        exit(0 if success else 1)
    except KeyboardInterrupt:
        print("\n\nTest interrupted by user")
        exit(1)
    except Exception as e:
        print(f"\n❌ Fatal error: {e}")
        import traceback
        traceback.print_exc()
        exit(1)
