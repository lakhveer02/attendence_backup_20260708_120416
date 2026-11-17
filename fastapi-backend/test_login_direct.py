#!/usr/bin/env python3
import os
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))

from dotenv import load_dotenv
load_dotenv()

from supabase import create_client

url = os.getenv("SUPABASE_URL")
key = os.getenv("SUPABASE_ANON_KEY")

print(f"Testing direct Supabase Auth login...")
print()

client = create_client(url, key)

print("1. Testing admin@squaidminds.com...")
try:
    result = client.auth.sign_in_with_password({
        "email": "admin@squaidminds.com",
        "password": "SquaidAdmin@123"
    })
    print(f"✅ Login successful! User ID: {result.user.id}")
except Exception as e:
    print(f"❌ Failed: {e}")

print()
print("2. Testing employee1@squaidminds.com...")
try:
    result = client.auth.sign_in_with_password({
        "email": "employee1@squaidminds.com",
        "password": "SquaidEmp1@123"
    })
    print(f"✅ Login successful! User ID: {result.user.id}")
except Exception as e:
    print(f"❌ Failed: {e}")
