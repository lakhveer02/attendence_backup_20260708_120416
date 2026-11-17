#!/usr/bin/env python3
"""Check profiles table schema"""

from app.database_complete import db_complete as db

print("\n" + "="*60)
print("PROFILES TABLE SCHEMA")
print("="*60 + "\n")

try:
    # Try to get one profile to see the structure
    response = db.client.table("profiles").select("*").limit(1).execute()
    
    if response.data and len(response.data) > 0:
        print("Sample profile fields:")
        profile = response.data[0]
        for key, value in profile.items():
            value_str = str(value)[:50] if value else "NULL"
            print(f"  - {key}: {value_str}")
    else:
        print("No profiles found in database")
        print("\nAttempting to get table structure...")
        
        # Try to insert a minimal record to see what fields are required
        print("\n(Table appears empty - cannot infer schema from data)")
        
except Exception as e:
    print(f"❌ Error: {e}")

print("\n" + "="*60 + "\n")
