"""
Test database connection and basic operations
"""
import asyncio
import sys
import os
from pathlib import Path

# Add parent directory to path
sys.path.insert(0, str(Path(__file__).parent))

from app.database_complete import db_complete as db

async def test_connection():
    """Test Supabase connection and basic queries"""
    print("=" * 60)
    print("🔍 Testing Database Connection")
    print("=" * 60)
    
    try:
        # Test 1: Get all companies
        print("\n✅ Test 1: Fetching companies...")
        companies = await db.get_all_companies()
        print(f"   Found {len(companies)} companies")
        if companies:
            print(f"   Sample: {companies[0].get('name', 'Unknown')}")
        
        # Test 2: Get all profiles
        print("\n✅ Test 2: Fetching profiles...")
        profiles = await db.get_all_profiles()
        print(f"   Found {len(profiles)} profiles")
        if profiles:
            print(f"   Sample: {profiles[0].get('email', 'Unknown')}")
        
        # Test 3: Get departments
        print("\n✅ Test 3: Fetching departments...")
        departments = await db.get_all_departments()
        print(f"   Found {len(departments)} departments")
        if departments:
            print(f"   Sample: {departments[0].get('name', 'Unknown')}")
        
        # Test 4: Get today's attendance
        print("\n✅ Test 4: Fetching today's attendance...")
        attendance = await db.get_all_attendance_today()
        print(f"   Found {len(attendance)} attendance records today")
        
        # Test 5: Get dashboard stats
        print("\n✅ Test 5: Fetching dashboard stats...")
        stats = await db.get_dashboard_stats()
        print(f"   Total Employees: {stats.get('total_employees', 0)}")
        print(f"   Present Today: {stats.get('present_today', 0)}")
        print(f"   Attendance Rate: {stats.get('attendance_rate_today', 0):.1f}%")
        
        print("\n" + "=" * 60)
        print("✅ All database tests passed!")
        print("=" * 60)
        return True
        
    except Exception as e:
        print(f"\n❌ Database test failed: {e}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == "__main__":
    success = asyncio.run(test_connection())
    sys.exit(0 if success else 1)
