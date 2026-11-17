#!/usr/bin/env python3
"""
Initialize Demo Company in Database
Creates a demo company for testing signup/login flow
"""

import os
import sys
from supabase import create_client
from dotenv import load_dotenv
from datetime import datetime
import uuid

# Load environment variables
load_dotenv()

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_SERVICE_KEY", os.getenv("SUPABASE_ANON_KEY"))

def main():
    """Initialize demo company"""
    try:
        print("🚀 Initializing Demo Company...")
        print()
        
        # Validate environment variables
        if not SUPABASE_URL or not SUPABASE_KEY:
            print("❌ Error: SUPABASE_URL and SUPABASE_SERVICE_KEY must be set in .env file")
            sys.exit(1)
        
        # Create Supabase client
        print(f"📡 Connecting to Supabase: {SUPABASE_URL}")
        supabase = create_client(SUPABASE_URL, SUPABASE_KEY)
        print("✅ Connected to Supabase")
        print()
        
        # Check if demo company already exists
        print("🔍 Checking for existing demo company...")
        existing = supabase.table('companies').select('*').eq('workspace_slug', 'demo-company').execute()
        
        if existing.data and len(existing.data) > 0:
            company = existing.data[0]
            print(f"✅ Demo company already exists!")
            print(f"   Company ID: {company['id']}")
            print(f"   Name: {company['name']}")
            print(f"   Workspace Slug: {company['workspace_slug']}")
            print(f"   Joining Token: {company.get('joining_token', 'N/A')}")
            print()
            print("🎯 Use this company_id in your Flutter app:")
            print(f"   {company['id']}")
            return
        
        # Create demo company
        print("📝 Creating demo company...")
        
        demo_company = {
            'id': '00000000-0000-0000-0000-000000000001',  # Fixed UUID for demo
            'name': 'Demo Company',
            'workspace_slug': 'demo-company',
            'joining_token': 'DEMO1234',
            'status': 'active',
            'subscription_plan': 'trial',
            'subscription_status': 'active',
            'trial_ends_at': (datetime.now().replace(year=datetime.now().year + 1)).isoformat(),
            'settings': {
                'timezone': 'Asia/Kolkata',
                'date_format': 'DD/MM/YYYY',
                'time_format': '24h',
                'currency': 'INR',
                'language': 'en'
            },
            'is_active': True,
            'created_at': datetime.now().isoformat(),
            'updated_at': datetime.now().isoformat()
        }
        
        result = supabase.table('companies').insert(demo_company).execute()
        
        if result.data and len(result.data) > 0:
            company = result.data[0]
            print("✅ Demo company created successfully!")
            print()
            print("📋 Company Details:")
            print(f"   Company ID: {company['id']}")
            print(f"   Name: {company['name']}")
            print(f"   Workspace Slug: {company['workspace_slug']}")
            print(f"   Joining Token: {company.get('joining_token', 'N/A')}")
            print(f"   Status: {company['status']}")
            print()
            print("🎯 Next Steps:")
            print("   1. Your Flutter app already uses this company_id")
            print("   2. Try signing up in the app")
            print("   3. Or use the joining token: DEMO1234")
            print()
        else:
            print("❌ Failed to create demo company")
            sys.exit(1)
            
    except Exception as e:
        print(f"❌ Error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

if __name__ == "__main__":
    main()
