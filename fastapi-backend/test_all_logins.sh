#!/bin/bash

echo "=========================================="
echo "Testing All User Logins for Squaid Minds"
echo "=========================================="
echo ""

# Test 1: Company Admin
echo "1️⃣  Testing Company Admin..."
RESULT=$(curl -s -X POST http://localhost:8000/api/v1/auth/login -H "Content-Type: application/json" -d '{
  "email": "admin@squaidminds.com",
  "password": "SquaidAdmin@123",
  "device_id": "test-device"
}')

if echo "$RESULT" | grep -q '"success": true'; then
  echo "✅ Company Admin login successful"
  echo "$RESULT" | python3 -m json.tool | grep -E '"email"|"role"|"company_name"' | head -3
else
  echo "❌ Company Admin login failed"
  echo "$RESULT" | python3 -m json.tool | grep "detail"
fi
echo ""

# Test 2: HR Manager
echo "2️⃣  Testing HR Manager..."
RESULT=$(curl -s -X POST http://localhost:8000/api/v1/auth/login -H "Content-Type: application/json" -d '{
  "email": "hr@squaidminds.com",
  "password": "SquaidHR@123",
  "device_id": "test-device"
}')

if echo "$RESULT" | grep -q '"success": true'; then
  echo "✅ HR Manager login successful"
  echo "$RESULT" | python3 -m json.tool | grep -E '"email"|"role"|"company_name"' | head -3
else
  echo "❌ HR Manager login failed"
  echo "$RESULT" | python3 -m json.tool | grep "detail"
fi
echo ""

# Test 3: Employee 1
echo "3️⃣  Testing Employee 1 (Rahul Kumar)..."
RESULT=$(curl -s -X POST http://localhost:8000/api/v1/auth/login -H "Content-Type: application/json" -d '{
  "email": "employee1@squaidminds.com",
  "password": "SquaidEmp1@123",
  "device_id": "test-device"
}')

if echo "$RESULT" | grep -q '"success": true'; then
  echo "✅ Employee 1 login successful"
  echo "$RESULT" | python3 -m json.tool | grep -E '"email"|"full_name"|"role"|"company_name"' | head -4
else
  echo "❌ Employee 1 login failed"
  echo "$RESULT" | python3 -m json.tool | grep "detail"
fi
echo ""

# Test 4: Employee 2
echo "4️⃣  Testing Employee 2 (Priya Sharma)..."
RESULT=$(curl -s -X POST http://localhost:8000/api/v1/auth/login -H "Content-Type: application/json" -d '{
  "email": "employee2@squaidminds.com",
  "password": "SquaidEmp2@123",
  "device_id": "test-device"
}')

if echo "$RESULT" | grep -q '"success": true'; then
  echo "✅ Employee 2 login successful"
  echo "$RESULT" | python3 -m json.tool | grep -E '"email"|"full_name"|"role"|"company_name"' | head -4
else
  echo "❌ Employee 2 login failed"
  echo "$RESULT" | python3 -m json.tool | grep "detail"
fi
echo ""

# Test 5: Super Admin
echo "5️⃣  Testing Super Admin..."
RESULT=$(curl -s -X POST http://localhost:8000/api/v1/auth/login -H "Content-Type: application/json" -d '{
  "email": "superadmin@squaidminds.com",
  "password": "SuperAdmin@123",
  "device_id": "test-device"
}')

if echo "$RESULT" | grep -q '"success": true'; then
  echo "✅ Super Admin login successful"
  echo "$RESULT" | python3 -m json.tool | grep -E '"email"|"role"|"full_name"' | head -3
else
  echo "❌ Super Admin login failed"
  echo "$RESULT" | python3 -m json.tool | grep "detail"
fi
echo ""

echo "=========================================="
echo "✅ Login Testing Complete!"
echo "=========================================="
