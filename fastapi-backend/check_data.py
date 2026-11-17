#!/usr/bin/env python3
"""Check existing data in database"""

import os
import json
from dotenv import load_dotenv
from supabase import create_client, Client

load_dotenv()
supabase_url = os.getenv('SUPABASE_URL')
supabase_key = os.getenv('SUPABASE_SERVICE_KEY')

supabase: Client = create_client(supabase_url, supabase_key)

print("=" * 80)
print("EXISTING DATABASE DATA")
print("=" * 80)

# Check companies
print("\n📦 COMPANIES:")
companies = supabase.table('companies').select('*').execute()
for c in companies.data:
    print(f"   ID: {c['id']}")
    print(f"   Name: {c['name']}")
    print(f"   Status: {c['status']}")
    print(f"   Workspace Slug: {c.get('workspace_slug')}")
    print(f"   Joining Token: {c.get('joining_token')}")
    print()

# Check profiles
print("👥 PROFILES:")
profiles = supabase.table('profiles').select('*').execute()
for p in profiles.data:
    print(f"   ID: {p['id']}")
    print(f"   Email: {p['email']}")
    print(f"   Name: {p['full_name']}")
    print(f"   Role: {p['role']}")
    print(f"   Company ID: {p['company_id']}")
    print(f"   Workspace ID: {p.get('workspace_id')}")
    print(f"   Active: {p['is_active']}")
    print()

# Check for profiles table schema fields
print("🔍 PROFILES TABLE SCHEMA CHECK:")
if profiles.data:
    sample = profiles.data[0]
    important_fields = [
        'password_hash', 'is_temporary_password', 'created_by', 
        'is_verified', 'is_email_verified', 'joining_date'
    ]
    for field in important_fields:
        exists = field in sample
        print(f"   {field}: {'✅ EXISTS' if exists else '❌ MISSING'}")

print("\n" + "=" * 80)
