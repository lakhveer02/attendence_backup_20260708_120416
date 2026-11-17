#!/usr/bin/env python
"""Test signup endpoint directly"""
import asyncio
import json
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

# Test signup
payload = {
    "email": "test@example.com",
    "password": "Veer1234",
    "full_name": "Test User"
}

print("\n=== Testing Signup Endpoint ===\n")
print(f"Payload: {json.dumps(payload, indent=2)}\n")

response = client.post(
    "/api/v1/auth/signup",
    json=payload,
    headers={"Content-Type": "application/json"}
)

print(f"Status Code: {response.status_code}")
print(f"Response: {json.dumps(response.json(), indent=2)}")
