#!/usr/bin/env python3
"""Check what tables exist in Supabase"""

from app.database_complete import db_complete as db

# Try to list all tables
tables_to_check = ['employees', 'profiles', 'companies', 'users', 'attendance', 'leaves']

print("\n" + "="*60)
print("CHECKING SUPABASE TABLES")
print("="*60 + "\n")

for table_name in tables_to_check:
    try:
        response = db.client.table(table_name).select("*").limit(1).execute()
        print(f"✅ Table '{table_name}' EXISTS (found {len(response.data)} rows)")
    except Exception as e:
        error_msg = str(e)
        if "PGRST205" in error_msg or "not find the table" in error_msg:
            print(f"❌ Table '{table_name}' DOES NOT EXIST")
        else:
            print(f"⚠️  Table '{table_name}' ERROR: {error_msg[:100]}")

print("\n" + "="*60 + "\n")
