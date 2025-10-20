#!/bin/bash

echo "======================================"
echo "🔍 Scan2Suggest Backend Connection Test"
echo "======================================"
echo ""

# Check if backend is running
echo "1️⃣ Checking if backend is running on port 3000..."
if lsof -Pi :3000 -sTCP:LISTEN -t >/dev/null ; then
    echo "   ✅ Backend is running"
else
    echo "   ❌ Backend is NOT running"
    echo "   💡 Start it with: cd backend && npm start"
    exit 1
fi

echo ""

# Get IP addresses
echo "2️⃣ Your computer's IP addresses:"
ifconfig | grep "inet " | grep -v 127.0.0.1 | awk '{print "   📍 " $2}'

echo ""

# Test health endpoint
echo "3️⃣ Testing API health endpoint..."
IP=$(ifconfig | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}' | head -n 1)
if [ ! -z "$IP" ]; then
    echo "   Testing: http://$IP:3000/api/health"
    RESPONSE=$(curl -s -w "\n%{http_code}" http://$IP:3000/api/health)
    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    BODY=$(echo "$RESPONSE" | head -n-1)
    
    if [ "$HTTP_CODE" == "200" ]; then
        echo "   ✅ API is responding correctly"
        echo "   Response: $BODY"
    else
        echo "   ❌ API returned HTTP $HTTP_CODE"
    fi
else
    echo "   ❌ Could not determine IP address"
fi

echo ""
echo "======================================"
echo "📱 Mobile App Configuration"
echo "======================================"
echo ""
echo "Update these values in mobile/lib/config/api_config.dart:"
echo ""
echo "   BACKEND_IP = '$IP'"
echo ""
echo "For real device: IS_REAL_DEVICE = true"
echo "For Android emulator: IS_ANDROID_EMULATOR = true"
echo "For iOS simulator: IS_IOS_SIMULATOR = true"
echo ""
echo "======================================"

