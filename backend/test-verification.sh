#!/bin/bash

echo "======================================"
echo "📧 Email Verification Test"
echo "======================================"
echo ""

# Generate random email for testing
RANDOM_EMAIL="test$RANDOM@example.com"

echo "1️⃣ Registering new user: $RANDOM_EMAIL"
echo ""

REGISTER_RESPONSE=$(curl -s -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d "{\"name\":\"Test User\",\"email\":\"$RANDOM_EMAIL\",\"password\":\"password123\"}")

echo "$REGISTER_RESPONSE" | python3 -m json.tool

# Extract verification code
VERIFICATION_CODE=$(echo "$REGISTER_RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin).get('verificationCode', ''))")

if [ -z "$VERIFICATION_CODE" ]; then
    echo ""
    echo "❌ Failed to get verification code"
    exit 1
fi

echo ""
echo "======================================"
echo "2️⃣ Verifying email with code: $VERIFICATION_CODE"
echo "======================================"
echo ""

curl -s -X POST http://localhost:3000/api/auth/verify-email \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$RANDOM_EMAIL\",\"code\":\"$VERIFICATION_CODE\"}" | python3 -m json.tool

echo ""
echo "======================================"
echo "✅ Email verification test complete!"
echo "======================================"

