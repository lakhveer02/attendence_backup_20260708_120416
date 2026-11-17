#!/usr/bin/env python3
"""List all users in the database"""

from app.database_complete import db_complete as db
import asyncio

async def list_users():
    print("\n" + "="*60)
    print("EXISTING USERS IN DATABASE")
    print("="*60 + "\n")
    
    try:
        profiles = await db.get_all_profiles()
        
        if not profiles:
            print("No users found in database")
            print("\n💡 Tip: Sign up first before trying to login!")
        else:
            print(f"Found {len(profiles)} users:\n")
            for i, profile in enumerate(profiles, 1):
                print(f"{i}. Email: {profile.get('email')}")
                print(f"   Name: {profile.get('full_name')}")
                print(f"   Role: {profile.get('role')}")
                print(f"   Company ID: {profile.get('company_id')}")
                print(f"   Active: {profile.get('is_active')}")
                print()
    except Exception as e:
        print(f"❌ Error: {e}")
    
    print("="*60 + "\n")

if __name__ == "__main__":
    asyncio.run(list_users())
