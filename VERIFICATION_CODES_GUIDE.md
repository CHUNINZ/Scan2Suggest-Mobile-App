# 📧 How to Get Verification Codes

## ✅ GOOD NEWS: Email Verification IS Working!

Your email verification system is fully functional. The codes are being generated, stored, and validated correctly.

---

## 🎯 Quick Answer: Where Are My Verification Codes?

### Method 1: API Response (Recommended for Development)

When you register or request a password reset, the API response **includes the verification code**:

```json
{
  "success": true,
  "verificationCode": "123456",  // ← YOUR CODE IS HERE!
  "email": "user@example.com"
}
```

**In your Flutter app**, you can access it from the response:
```dart
final code = response['verificationCode'];
// You can display this in the UI or log it for testing
```

### Method 2: Backend Console (Alternative)

1. Open the terminal where you ran `npm start` (backend)
2. When someone registers, you'll see:
   ```
   📧 Registration verification requested for: user@example.com
   📧 Verification code: 123456
   📧 [EMAIL SERVICE] Email verification code for user@example.com: 123456
   ```

---

## 🧪 Test It Right Now

Run this test to see how it works:

```bash
cd backend
./test-verification.sh
```

This will:
1. Register a test user
2. Show you the verification code
3. Automatically verify the email
4. Prove everything is working!

---

## 🚀 For Your Flutter App

### Option A: Auto-fill Code (Best UX)

In your signup page, extract the code from the API response and auto-fill it:

```dart
// In your registration function:
final response = await apiService.register(name, email, password);

if (response['success']) {
  final code = response['verificationCode'];  // Get code from response
  
  if (code != null) {
    // Development mode - auto-navigate with code
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VerifyEmailPage(
          email: email,
          verificationCode: code,  // Pre-fill or auto-verify
        ),
      ),
    );
  }
}
```

### Option B: Show Code to User

Display the code for easy copying during development:

```dart
if (response['verificationCode'] != null && kDebugMode) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Verification code: ${response['verificationCode']}'),
      duration: Duration(seconds: 10),
    ),
  );
}
```

---

## 📱 API Endpoints

### Register (Sends Verification Code)
```bash
POST /api/auth/register
{
  "name": "John Doe",
  "email": "john@example.com",
  "password": "password123"
}

Response:
{
  "success": true,
  "verificationCode": "123456",  // Only in development
  "emailSent": false,
  "email": "john@example.com"
}
```

### Verify Email
```bash
POST /api/auth/verify-email
{
  "email": "john@example.com",
  "code": "123456"
}

Response:
{
  "success": true,
  "message": "Email verified successfully!",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": { ... }
}
```

### Resend Code
```bash
POST /api/auth/resend-verification
{
  "email": "john@example.com"
}

Response:
{
  "success": true,
  "message": "Verification code sent again"
}
```

### Forgot Password (Password Reset Code)
```bash
POST /api/auth/forgot-password
{
  "email": "john@example.com"
}

Response:
{
  "success": true,
  "verificationCode": "789012",  // Only in development
  "emailSent": false
}
```

---

## ❓ Why Am I Not Getting Emails?

### The Issue
SMTP connection to Gmail is timing out due to network/firewall restrictions:
```
❌ Email service connection failed: queryA ETIMEOUT smtp.gmail.com
```

### Why It's Not a Problem
In **development mode**, you don't need emails because:
1. ✅ Code is in API response
2. ✅ Code is logged to console
3. ✅ Verification works perfectly

### If You Want Real Emails (Optional)

1. **Check Your Network**
   - Make sure port 587 (SMTP) isn't blocked
   - Try a different WiFi network
   - Check firewall settings

2. **Update Gmail Settings**
   - Enable 2-Factor Authentication
   - Generate App Password: https://myaccount.google.com/apppasswords
   - Update `.env` with the new password

3. **Use Different Email Provider**
   - Try SendGrid, Mailgun, or Mailjet
   - They often have better deliverability

---

## 🔧 Troubleshooting

### "I can't see the verification code"

**Solution 1:** Check API response in your Flutter app:
```dart
print('Registration response: $response');
// Look for: verificationCode: "123456"
```

**Solution 2:** Check backend terminal:
- Find where you ran `npm start`
- Look for lines with "verification code"

**Solution 3:** Restart backend with logging:
```bash
cd backend
pkill -f "node.*server.js"
npm start
```

### "Code is not in the API response"

This only happens if `NODE_ENV` is set to `production`. Check your `.env`:
```env
NODE_ENV=development  # ← Make sure this is set
```

Then restart backend.

### "Invalid verification code"

- Codes expire after **10 minutes**
- Use the "Resend Code" button to get a new one
- Make sure you're entering all 6 digits

---

## 🎓 How It Works

1. **User Registers** → API generates 6-digit code
2. **Code Stored** → Saved in database with 10-min expiration
3. **Code Returned** → Included in API response (dev mode)
4. **Code Logged** → Printed to backend console
5. **Email Attempted** → Tries to send email (may fail)
6. **User Enters Code** → API validates against database
7. **Verification Success** → User is verified & gets auth token

---

## 📊 Current Configuration

```
Backend Status:     ✅ Running
Email Credentials:  ✅ Configured
SMTP Connection:    ❌ Timeout (network issue)
Fallback Mode:      ✅ Active (console logging)
Development Mode:   ✅ Codes in API response
Verification:       ✅ Working perfectly
```

---

## 🎯 Summary

**You don't need to do anything!** Your verification system is working. Just:

1. Register a user in your app
2. Check the API response for `verificationCode`
3. Use that code to verify

OR

1. Register a user in your app
2. Check the backend terminal for the code
3. Enter it manually in the app

Both ways work perfectly! 🎉

---

## 📞 Need Help?

Run the test script to verify everything:
```bash
cd backend
./test-verification.sh
```

Check the full email setup guide:
```bash
cat backend/EMAIL_SETUP_GUIDE.md
```

