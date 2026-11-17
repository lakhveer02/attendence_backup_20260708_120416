#!/usr/bin/env python3
"""
Fix passwords for Squaid Minds users
"""
import os
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))

from app.database_complete import db_complete as db

users = [
    {"user_id": "4b1906f4-16b6-4e06-8e7a-6e0f43696664", "email": "admin@squaidminds.com", "password": "SquaidAdmin@123"},
    {"user_id": "0e3b8597-5a31-4b1d-88c0-ded6cd85b501", "email": "hr@squaidminds.com", "password": "SquaidHR@123"},
    {"user_id": "fcd106ec-6ddf-48bb-88b2-6884a80faadf", "email": "employee1@squaidminds.com", "password": "SquaidEmp1@123"},
    {"user_id": "3b046912-5b06-4a7f-a2b6-29ca18831014", "email": "employee2@squaidminds.com", "password": "SquaidEmp2@123"},
    {"user_id": "f864d948-ed27-4e2a-878f-a738e9cfb6f0", "email": "superadmin@squaidminds.com", "password": "SuperAdmin@123"},
]

print("🔧 Fixing user passwords...")
print()

for user in users:
    print(f"Updating password for {user['email']}...")
    try:
        db.client.auth.admin.update_user_by_id(
            user['user_id'],
            {"password": user['password']}
        )
        print(f"   ✅ Password updated")
    except Exception as e:
        print(f"   ❌ Error: {e}")
    print()

print("✅ Done!")
