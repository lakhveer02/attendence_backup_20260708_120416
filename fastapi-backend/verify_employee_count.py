"""
Verify Employee Count in Database
Tests that all 12 employees exist and dashboard will show correct count
"""

import asyncio
import sys
from pathlib import Path

# Add parent directory to path
sys.path.insert(0, str(Path(__file__).parent))

from app.database_complete import db_complete as db

COMPANY_ID = "01e20568-18c6-4020-a3b3-6c717a023baf"

async def verify_employee_count():
    """Verify employee count using the dashboard method"""
    print("=" * 60)
    print("VERIFYING EMPLOYEE COUNT")
    print("=" * 60)
    
    try:
        # Use the same method dashboard uses
        count = await db.get_company_employee_count(COMPANY_ID)
        
        print(f"\n✅ Employee Count (Dashboard Method): {count}")
        
        if count == 12:
            print("✅ PERFECT! All 12 employees found")
        elif count == 0:
            print("❌ PROBLEM: Count is 0 - Dashboard will show 0")
            print("\nDebugging...")
            
            # Try direct query
            response = db.client.table("profiles").select("*").eq("company_id", COMPANY_ID).eq("is_active", True).execute()
            
            print(f"\nDirect query found {len(response.data)} employees:")
            for emp in response.data:
                print(f"  - {emp.get('full_name')} ({emp.get('email')}) - Role: {emp.get('role')}")
        else:
            print(f"⚠️  UNEXPECTED: Found {count} employees (expected 12)")
        
        print("\n" + "=" * 60)
        return count
        
    except Exception as e:
        print(f"❌ ERROR: {e}")
        import traceback
        traceback.print_exc()
        return 0

if __name__ == "__main__":
    count = asyncio.run(verify_employee_count())
    sys.exit(0 if count == 12 else 1)
