#!/usr/bin/env python3
"""Quick script to check actual Supabase schema"""

import os
from dotenv import load_dotenv
from supabase import create_client, Client

load_dotenv()
supabase_url = os.getenv('SUPABASE_URL')
supabase_key = os.getenv('SUPABASE_SERVICE_ROLE_KEY') or os.getenv('SUPABASE_SERVICE_KEY')

if supabase_url and supabase_key:
    supabase: Client = create_client(supabase_url, supabase_key)
    
    print("=" * 60)
    print("CHECKING SUPABASE SCHEMA")
    print("=" * 60)
    
    # Check what tables actually exist
    try:
        # Try profiles table
        profiles = supabase.table('profiles').select('*').limit(1).execute()
        print('\n✅ profiles table EXISTS')
        if profiles.data:
            print(f'   Columns: {list(profiles.data[0].keys())}')
        else:
            print('   (No data in table)')
    except Exception as e:
        print(f'\n❌ profiles table: {str(e)[:150]}')
    
    try:
        # Try employees table
        employees = supabase.table('employees').select('*').limit(1).execute()
        print('\n✅ employees table EXISTS')
        if employees.data:
            print(f'   Columns: {list(employees.data[0].keys())}')
        else:
            print('   (No data in table)')
    except Exception as e:
        print(f'\n❌ employees table: {str(e)[:150]}')
    
    # Check companies table structure
    try:
        companies = supabase.table('companies').select('*').limit(1).execute()
        print('\n✅ companies table EXISTS')
        if companies.data:
            cols = list(companies.data[0].keys())
            print(f'   Total columns: {len(cols)}')
            print(f'   Key columns: {[c for c in cols if c in ["id", "name", "status", "workspace_slug", "joining_token"]]}')
    except Exception as e:
        print(f'\n❌ companies table: {str(e)[:150]}')
    
    # Check existing data
    try:
        profiles_count = supabase.table('profiles').select('*', count='exact').execute()
        print(f'\n📊 profiles table: {profiles_count.count} records')
    except:
        pass
    
    try:
        employees_count = supabase.table('employees').select('*', count='exact').execute()
        print(f'📊 employees table: {employees_count.count} records')
    except:
        pass
    
    try:
        companies_count = supabase.table('companies').select('*', count='exact').execute()
        print(f'📊 companies table: {companies_count.count} records')
    except:
        pass
    
    print("\n" + "=" * 60)
else:
    print('❌ Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY')
