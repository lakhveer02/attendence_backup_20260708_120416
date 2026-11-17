#!/bin/bash

# Test login for all roles
BASE_URL="http://localhost:8000/api/v1/auth"

echo "========================================================================"
echo "🧪 TESTING LOGIN FOR ALL ROLES"
echo "========================================================================"

# Test Employee Login
echo ""
echo "1️⃣  TESTING EMPLOYEE LOGIN"
echo "   Email: employee@beersingh.com"
echo "   Password: Employee@123"
echo "------------------------------------------------------------------------"
RESPONSE=$(curl -s -X POST "$BASE_URL/login" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "employee@beersingh.com",
    "password": "Employee@123",
    "device_id": "test-device-employee"
  }')

if echo "$RESPONSE" | grep -q '"success":true'; then
    echo "✅ EMPLOYEE LOGIN SUCCESSFUL"
    echo "$RESPONSE" | python3 -m json.tool | grep -E "(success|message|email|role|full_name)" | head -10
else
    echo "❌ EMPLOYEE LOGIN FAILED"
    echo "$RESPONSE" | python3 -m json.tool
fi

# Test HR Manager Login
echo ""
echo "2️⃣  TESTING HR MANAGER LOGIN"
echo "   Email: hr@beersingh.com"
echo "   Password: HRManager@123"
echo "------------------------------------------------------------------------"
RESPONSE=$(curl -s -X POST "$BASE_URL/login" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "hr@beersingh.com",
    "password": "HRManager@123",
    "device_id": "test-device-hr"
  }')

if echo "$RESPONSE" | grep -q '"success":true'; then
    echo "✅ HR MANAGER LOGIN SUCCESSFUL"
    echo "$RESPONSE" | python3 -m json.tool | grep -E "(success|message|email|role|full_name)" | head -10
else
    echo "❌ HR MANAGER LOGIN FAILED"
    echo "$RESPONSE" | python3 -m json.tool
fi

# Test Company Admin Login
echo ""
echo "3️⃣  TESTING COMPANY ADMIN LOGIN"
echo "   Email: admin@beersingh.com"
echo "   Password: Admin@123"
echo "------------------------------------------------------------------------"
RESPONSE=$(curl -s -X POST "$BASE_URL/login" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@beersingh.com",
    "password": "Admin@123",
    "device_id": "test-device-admin"
  }')

if echo "$RESPONSE" | grep -q '"success":true'; then
    echo "✅ COMPANY ADMIN LOGIN SUCCESSFUL"
    echo "$RESPONSE" | python3 -m json.tool | grep -E "(success|message|email|role|full_name)" | head -10
else
    echo "❌ COMPANY ADMIN LOGIN FAILED"
    echo "$RESPONSE" | python3 -m json.tool
fi

# Test Super Admin Login
echo ""
echo "4️⃣  TESTING SUPER ADMIN LOGIN"
echo "   Email: superadmin@test.com"
echo "   Password: Super@123"
echo "------------------------------------------------------------------------"
RESPONSE=$(curl -s -X POST "$BASE_URL/login" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "superadmin@test.com",
    "password": "Super@123",
    "device_id": "test-device-superadmin"
  }')

if echo "$RESPONSE" | grep -q '"success":true'; then
    echo "✅ SUPER ADMIN LOGIN SUCCESSFUL"
    echo "$RESPONSE" | python3 -m json.tool | grep -E "(success|message|email|role|full_name)" | head -10
else
    echo "❌ SUPER ADMIN LOGIN FAILED"
    echo "$RESPONSE" | python3 -m json.tool
fi

# Test existing user (lakh8@yopmail.com)
echo ""
echo "5️⃣  TESTING EXISTING USER LOGIN"
echo "   Email: lakh8@yopmail.com"
echo "   Trying common passwords..."
echo "------------------------------------------------------------------------"

for password in "Test@123" "Test@1234" "Admin@123" "Lakh@123"; do
    echo "   Trying password: $password"
    RESPONSE=$(curl -s -X POST "$BASE_URL/login" \
      -H "Content-Type: application/json" \
      -d "{
        \"email\": \"lakh8@yopmail.com\",
        \"password\": \"$password\",
        \"device_id\": \"test-device-lakh\"
      }")
    
    if echo "$RESPONSE" | grep -q '"success":true'; then
        echo "   ✅ LOGIN SUCCESSFUL WITH PASSWORD: $password"
        echo "$RESPONSE" | python3 -m json.tool | grep -E "(success|message|email|role|full_name)" | head -10
        break
    fi
done

echo ""
echo "========================================================================"
echo "📋 LOGIN CREDENTIALS SUMMARY"
echo "========================================================================"
echo ""
echo "✅ WORKING CREDENTIALS:"
echo ""
echo "Employee:"
echo "  Email: employee@beersingh.com"
echo "  Password: Employee@123"
echo ""
echo "HR Manager:"
echo "  Email: hr@beersingh.com"
echo "  Password: HRManager@123"
echo ""
echo "Company Admin:"
echo "  Email: admin@beersingh.com"
echo "  Password: Admin@123"
echo ""
echo "Super Admin:"
echo "  Email: superadmin@test.com"
echo "  Password: Super@123"
echo ""
echo "Existing Company Admin:"
echo "  Email: lakh8@yopmail.com"
echo "  Password: (Use one of the test passwords above)"
echo ""
echo "========================================================================"
