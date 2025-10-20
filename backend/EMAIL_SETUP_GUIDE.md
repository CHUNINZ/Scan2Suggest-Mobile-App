# 📧 Email Verification Setup Guide

## Current Status

✅ **Email credentials are configured** in `.env`:
- EMAIL_USER: scansuggest@gmail.com
- EMAIL_PASS: [configured]

❌ **SMTP connection is timing out** (network/firewall issue)

✅ **Fallback mode is active**: Verification codes are logged to the backend console

---

## 🚀 Quick Solution (Development Mode)

Since SMTP isn't working, your app is using **console logging mode**. Verification codes are printed to the backend terminal.

### How to Get Verification Codes:

1. **Stop your current backend** (if running in background)
2. **Start backend with visible logging**:
   ```bash
   cd backend
   npm start
   ```
3. **Register a new account** in your app
4. **Check the terminal** - you'll see:
   ```
   📧 [EMAIL SERVICE] Email verification code for user@example.com: 123456
   ```

---

## 🔧 Fix SMTP Email (For Production)

The SMTP timeout error means Gmail's SMTP server isn't reachable. Here are solutions:

### Option 1: Use Gmail App Password (Recommended)

1. **Enable 2-Factor Authentication** on your Gmail account
2. **Generate an App Password**:
   - Go to: https://myaccount.google.com/apppasswords
   - Select "Mail" and your device
   - Copy the 16-character password
3. **Update `.env`**:
   ```env
   EMAIL_USER=scansuggest@gmail.com
   EMAIL_PASS=your_16_char_app_password_here
   ```
4. **Restart backend**: `npm start`

### Option 2: Enable Less Secure Apps (Not Recommended)

If you don't have 2FA:
1. Go to: https://myaccount.google.com/lesssecureapps
2. Turn ON "Allow less secure apps"
3. Restart backend

### Option 3: Use Different Email Service

Update `.env` to use a different SMTP provider:

**SendGrid:**
```env
EMAIL_HOST=smtp.sendgrid.net
EMAIL_PORT=587
EMAIL_USER=apikey
EMAIL_PASS=your_sendgrid_api_key
```

**Mailgun:**
```env
EMAIL_HOST=smtp.mailgun.org
EMAIL_PORT=587
EMAIL_USER=postmaster@your-domain.mailgun.org
EMAIL_PASS=your_mailgun_password
```

---

## 🧪 Test Email Configuration

Run this command to test your email setup:
```bash
cd backend
node -e "require('dotenv').config(); const emailService = require('./services/emailService'); setTimeout(() => emailService.testConnection().then(r => console.log(r)), 2000);"
```

Or test by sending a verification code:
```bash
curl -X POST http://localhost:3000/api/auth/forgot-password \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com"}'
```

---

## 📝 Development Workflow

### Current Setup (Console Logging)

**Registration Flow:**
1. User registers in app
2. Backend generates 6-digit code
3. Code is **logged to console** (since SMTP isn't working)
4. You manually check the backend terminal for the code
5. Enter the code in the app to verify

**To find codes:**
```bash
# If backend is running in foreground - check the terminal
# If backend is running in background - check logs:
cd backend
cat backend.log | grep "verification code"
```

---

## 🔍 Troubleshooting

### "No email transporter configured"
- The .env file is loaded correctly
- SMTP connection failed
- Fallback to console logging is active
- **Solution**: Check backend terminal for codes

### "Connection timeout" or "ETIMEOUT smtp.gmail.com"
- Firewall blocking SMTP port (587 or 465)
- Network restrictions
- **Solution**: 
  - Check firewall settings
  - Try different network
  - Use console logging for development
  - Or use a different SMTP provider

### "Invalid credentials"
- Wrong Gmail password
- Need App Password if 2FA is enabled
- **Solution**: Generate new App Password

### Can't see verification codes
- Backend running in background
- **Solution**: 
  ```bash
  # Stop background process
  pkill -f "node.*server.js"
  
  # Start in foreground
  cd backend
  npm start
  ```

---

## 📱 API Response Format

When you register or request password reset, the API returns:

```json
{
  "success": true,
  "message": "Verification code sent to your email",
  "verificationCode": "123456",  // Only in development mode
  "emailSent": false  // false = fallback to console
}
```

- `verificationCode`: **Only included in development mode** for easy testing
- `emailSent`: `true` if email sent successfully, `false` if using console fallback

---

## ✅ Verification

Your app should work fine with console logging! The verification codes are:
- ✅ Generated correctly
- ✅ Stored in database
- ✅ Logged to console
- ✅ Included in API response (dev mode)
- ✅ Validated on submission

The only difference is you need to check the backend terminal instead of email.

