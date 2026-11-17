#!/usr/bin/env python3
"""
Test Dashboard Employee Count
Verifies that the dashboard shows correct employee count
"""

import os
import sys
from supabase import create_client
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Add app to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'app'))

from database_complete import CompleteSupabaseDB

async def test_count():
    """Test employee count"""
    print("=" * 70)
    print("🧪 Testing Dashboard Employee Count")
    print("=" * 70)
    print()
    
    try:
        # Initialize database
        db = CompleteSupabaseDB()
        company_id = "01e20568-18c6-4020-a3b3-6c717a023baf"
        
        print(f"📊 Testing employee count for company: {company_id}")
        print()
        
        # Test the execute_query method with COUNT query
        result = await db.execute_query(
            """
            SELECT COUNT(*) as count
            FROM profiles
            WHERE company_id = $1 AND is_active = true
            """,
            company_id
        )
        
        print(f"Result: {result}")
        
        if result:
            count = result[0]['count']
            print(f"✅ Employee count: {count}")
            
            if count == 12:
                print("🎉 SUCCESS! All 12 employees found!")
            else:
                print(f"⚠️  Expected 12 employees, got {count}")
        else:
            print("❌ No result returned")
        
        print()
        print("=" * 70)
        
        # Also test direct table query
        print()
        print("Testing direct Supabase table query...")
        response = db.client.table("profiles").select("id", count="exact").eq("company_id", company_id).eq("is_active", True).execute()
        print(f"Direct count: {response.count}")
        
        if response.count == 12:
            print("✅ Direct query also shows 12 employees!")
        
        print()
        print("=" * 70)
        
    except Exception as e:
        print(f"❌ Error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)


if __name__ == "__main__":
    import asyncio
    asyncio.run(test_count())
