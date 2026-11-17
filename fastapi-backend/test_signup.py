#!/usr/bin/env python
"""Test signup endpoint"""
import asyncio
import json
from app.auth.routes import SignupRequest

# Test if the model can be instantiated
try:
    request = SignupRequest(
        email="test@example.com",
        password="Veer1234",
        full_name="Test User"
    )
    print("✅ Model instantiation successful!")
    print(f"Request data: {request.model_dump_json(indent=2)}")
except Exception as e:
    print(f"❌ Model instantiation failed: {e}")
    import traceback
    traceback.print_exc()
