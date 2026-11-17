#!/usr/bin/env python3
"""Test workspace creation endpoint"""

import requests
import json
import random
import string

BASE_URL = "http://localhost:8000"

def test_workspace_create():
    """Test creating a workspace"""
    print("\n" + "="*60)
    print("TEST: Workspace Create Endpoint")
    print("="*60)
    
    # Generate random slug
    random_id = ''.join(random.choices(string.ascii_lowercase + string.digits, k=8))
    
    payload = {
        "name": f"Test Company {random_id}",
        "slug": f"test-company-{random_id}",
        "industry": "Technology",
        "size": "small",
        "timezone": "UTC",
        "owner_email": f"owner-{random_id}@test.com",
        "owner_full_name": "Test Owner",
        "owner_password": "Test@1234"
    }
    
    print(f"\n📤 Sending request to: {BASE_URL}/api/v1/workspace/create")
    print(f"Payload: {json.dumps(payload, indent=2)}")
    
    try:
        response = requests.post(
            f"{BASE_URL}/api/v1/workspace/create",
            json=payload,
            headers={"Content-Type": "application/json"}
        )
        
        print(f"\n📥 Response Status: {response.status_code}")
        print(f"Response Body: {response.text}")
        
        if response.status_code in [200, 201]:
            print("✅ Workspace created successfully!")
            data = response.json()
            print(f"Company ID: {data.get('id')}")
            print(f"Company Name: {data.get('name')}")
            print(f"Slug: {data.get('slug')}")
        else:
            print(f"❌ Failed to create workspace")
            
    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    test_workspace_create()
