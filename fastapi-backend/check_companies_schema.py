#!/usr/bin/env python3
"""Check companies table schema"""

from app.database_complete import db_complete as db

print("\n" + "="*60)
print("COMPANIES TABLE SCHEMA")
print("="*60 + "\n")

try:
    # Get one company to see the structure
    response = db.client.table("companies").select("*").limit(1).execute()
    
    if response.data and len(response.data) > 0:
        print("Sample company fields:")
        company = response.data[0]
        for key, value in company.items():
            value_str = str(value)[:50] if value else "NULL"
            print(f"  - {key}: {value_str}")
    else:
        print("No companies found in database")
        
except Exception as e:
    print(f"❌ Error: {e}")

print("\n" + "="*60 + "\n")
