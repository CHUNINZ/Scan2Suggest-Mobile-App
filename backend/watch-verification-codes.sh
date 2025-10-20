#!/bin/bash

echo "======================================"
echo "📧 Verification Code Monitor"
echo "======================================"
echo ""
echo "This will show all verification codes from the backend logs."
echo "When you register or request a password reset, the code will appear here."
echo ""
echo "Press Ctrl+C to stop watching"
echo "======================================"
echo ""

# Find the backend process
BACKEND_PID=$(ps aux | grep "node.*server.js" | grep -v grep | awk '{print $2}' | head -n 1)

if [ -z "$BACKEND_PID" ]; then
    echo "❌ Backend server is not running"
    echo "💡 Start it with: cd backend && npm start"
    exit 1
fi

echo "✅ Monitoring backend process (PID: $BACKEND_PID)"
echo ""

# Monitor the process logs
# Since we can't easily tail the stdout of an existing process, 
# we'll create a simple test
echo "💡 To test email verification:"
echo "   1. Try to register a new account in your app"
echo "   2. The verification code will be logged to the backend console"
echo ""
echo "🔍 Recent backend logs:"
echo ""

# If there's a log file, tail it
if [ -f "backend.log" ]; then
    tail -f backend.log | grep --line-buffered -E "(Verification code|verification code|EMAIL SERVICE)"
else
    echo "⚠️  No log file found. Backend logs are going to the console where you started npm start"
    echo ""
    echo "💡 To see verification codes:"
    echo "   1. Stop the backend (Ctrl+C where it's running)"
    echo "   2. Start with logging: npm start | tee backend.log"
    echo "   3. Or check the terminal where you ran 'npm start'"
fi

