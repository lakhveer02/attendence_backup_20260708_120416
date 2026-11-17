#!/bin/bash

# Test Endpoints Script
# Run this after starting the backend to verify all endpoints work

echo "🧪 Testing FastAPI Endpoints"
echo "============================"
echo ""

BASE_URL="http://localhost:8000"

# Test 1: Root endpoint
echo "1️⃣ Testing root endpoint..."
curl -s $BASE_URL/ | python3 -m json.tool
echo ""
echo ""

# Test 2: Health check
echo "2️⃣ Testing health check..."
curl -s $BASE_URL/health | python3 -m json.tool
echo ""
echo ""

# Test 3: Profiles endpoint (the one that was failing)
echo "3️⃣ Testing profiles endpoint..."
curl -s $BASE_URL/api/v1/profiles | python3 -m json.tool
echo ""
echo ""

# Test 4: Create a test employee
echo "4️⃣ Creating test employee..."
curl -s -X POST $BASE_URL/api/v1/auth/signup \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "test123",
    "full_name": "Test Employee",
    "role": "employee",
    "phone_number": "+1234567890"
  }' | python3 -m json.tool
echo ""
echo ""

# Test 5: Check profiles again (should show the new employee)
echo "5️⃣ Checking profiles again..."
curl -s $BASE_URL/api/v1/profiles | python3 -m json.tool
echo ""
echo ""

echo "✅ All tests complete!"
echo ""
echo "If you see 404 errors, the backend is running the wrong file."
echo "Make sure to restart with: python -m uvicorn app.main:app --reload --port 8000"
