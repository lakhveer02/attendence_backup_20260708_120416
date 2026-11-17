#!/bin/bash

echo "================================================================================"
echo "🧪 Testing Ngrok API"
echo "================================================================================"
echo ""

NGROK_URL="https://5ad9-223-181-23-60.ngrok-free.app"

echo "📡 API Base URL: $NGROK_URL"
echo ""

# Test 1: Health check
echo "Test 1: Health Check"
echo "--------------------"
curl -s "$NGROK_URL/health" | python3 -m json.tool 2>/dev/null || echo "Health endpoint not available"
echo ""
echo ""

# Test 2: Login with CEO credentials
echo "Test 2: Login API (CEO)"
echo "--------------------"
curl -s -X POST "$NGROK_URL/api/v1/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"email":"chantenbarta@squadminds.com","password":"Ceo@2024Squad","device_id":"test-123","device_name":"Test"}' \
  | python3 -m json.tool 2>/dev/null || curl -s -X POST "$NGROK_URL/api/v1/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"email":"chantenbarta@squadminds.com","password":"Ceo@2024Squad","device_id":"test-123","device_name":"Test"}'
echo ""
echo ""

# Test 3: Signup API
echo "Test 3: Signup API (New User)"
echo "--------------------"
curl -s -X POST "$NGROK_URL/api/v1/auth/signup" \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"Test@1234","full_name":"Test User","role":"employee"}' \
  | python3 -m json.tool 2>/dev/null || curl -s -X POST "$NGROK_URL/api/v1/auth/signup" \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"Test@1234","full_name":"Test User","role":"employee"}'
echo ""
echo ""

echo "================================================================================"
echo "✅ API Tests Complete"
echo "================================================================================"
