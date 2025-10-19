const nodemailer = require('nodemailer');

class EmailService {
  constructor() {
    this.transporter = null;
    this.initializeTransporter();
  }

  initializeTransporter() {
    // Check if email credentials are provided
    if (!process.env.EMAIL_USER || !process.env.EMAIL_PASS) {
      console.log('⚠️  No email credentials found. Using test mode (codes will be logged to console).');
      console.log('📧 To enable real emails, create a .env file with EMAIL_USER and EMAIL_PASS');
      this.transporter = null;
      return;
    }

    // Try to create transporter with different configurations
    try {
      // Option 1: Gmail service (most common)
      if (process.env.EMAIL_USER.includes('@gmail.com')) {
        this.transporter = nodemailer.createTransport({
          service: 'gmail',
          auth: {
            user: process.env.EMAIL_USER,
            pass: process.env.EMAIL_PASS 
          }
        });
        console.log('📧 Email service configured for Gmail');
      }
      // Option 2: Custom SMTP configuration
      else if (process.env.EMAIL_HOST) {
        this.transporter = nodemailer.createTransport({
          host: process.env.EMAIL_HOST,
          port: process.env.EMAIL_PORT || 587,
          secure: process.env.EMAIL_SECURE === 'true',
          auth: {
            user: process.env.EMAIL_USER,
            pass: process.env.EMAIL_PASS
          }
        });
        console.log(`📧 Email service configured for custom SMTP: ${process.env.EMAIL_HOST}`);
      }
      // Option 3: Try Gmail as fallback
      else {
        this.transporter = nodemailer.createTransport({
          service: 'gmail',
          auth: {
            user: process.env.EMAIL_USER,
            pass: process.env.EMAIL_PASS 
          }
        });
        console.log('📧 Email service configured with Gmail as fallback');
      }

      // Test the connection
      this.testConnection().then(result => {
        if (result.success) {
          console.log('✅ Email service connection successful');
        } else {
          console.log('❌ Email service connection failed:', result.message);
          console.log('📧 Falling back to console logging mode');
          this.transporter = null;
        }
      });

    } catch (error) {
      console.error('❌ Error initializing email transporter:', error.message);
      console.log('📧 Falling back to console logging mode');
      this.transporter = null;
    }
  }

  async sendPasswordResetCode(email, code) {
    try {
      if (!this.transporter) {
        console.log(`📧 [EMAIL SERVICE] Password reset code for ${email}: ${code}`);
        console.log(`📧 [EMAIL SERVICE] To enable real emails, set EMAIL_USER and EMAIL_PASS in .env`);
        return { success: true, message: 'Code logged to console (development mode)' };
      }

      const mailOptions = {
        from: process.env.EMAIL_USER,
        to: email,
        subject: 'Password Reset Verification Code - Scan2Suggest',
        html: `
          <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
            <div style="text-align: center; margin-bottom: 30px;">
              <h1 style="color: #00412E; margin-bottom: 10px;">Scan2Suggest</h1>
              <h2 style="color: #666; font-weight: normal;">Password Reset Request</h2>
            </div>
            
            <div style="background-color: #f8f9fa; padding: 30px; border-radius: 10px; text-align: center;">
              <p style="font-size: 16px; color: #333; margin-bottom: 20px;">
                You requested to reset your password. Use the verification code below:
              </p>
              
              <div style="background-color: #00412E; color: white; font-size: 32px; font-weight: bold; padding: 20px; border-radius: 8px; letter-spacing: 4px; margin: 20px 0;">
                ${code}
              </div>
              
              <p style="font-size: 14px; color: #666; margin-top: 20px;">
                This code will expire in 10 minutes for security reasons.
              </p>
            </div>
            
            <div style="margin-top: 30px; padding-top: 20px; border-top: 1px solid #eee; text-align: center;">
              <p style="font-size: 12px; color: #999;">
                If you didn't request this password reset, please ignore this email.
              </p>
              <p style="font-size: 12px; color: #999;">
                This is an automated message, please do not reply.
              </p>
            </div>
          </div>
        `
      };

      const info = await this.transporter.sendMail(mailOptions);
      console.log(`📧 [EMAIL SERVICE] Password reset code sent to ${email}`);
      
      return { 
        success: true, 
        message: 'Password reset code sent successfully',
        messageId: info.messageId 
      };

    } catch (error) {
      console.error('📧 [EMAIL SERVICE] Error sending password reset email:', error);
      console.log(`📧 [EMAIL SERVICE] FALLBACK - Password reset code for ${email}: ${code}`);
      
      return { 
        success: true, 
        message: 'Email service unavailable, code logged to console',
        fallback: true 
      };
    }
  }

  async sendEmailVerificationCode(email, code) {
    try {
      // If no transporter configured, just log the code (development mode)
      if (!this.transporter) {
        console.log(`📧 [EMAIL SERVICE] Email verification code for ${email}: ${code}`);
        console.log(`📧 [EMAIL SERVICE] To enable real emails, set EMAIL_USER and EMAIL_PASS in .env`);
        return { success: true, message: 'Code logged to console (development mode)' };
      }

      const mailOptions = {
        from: process.env.EMAIL_USER,
        to: email,
        subject: 'Welcome to Scan2Suggest - Verify Your Email',
        html: `
          <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
            <div style="text-align: center; margin-bottom: 30px;">
              <h1 style="color: #00412E; margin-bottom: 10px;">Welcome to Scan2Suggest!</h1>
              <h2 style="color: #666; font-weight: normal;">Email Verification Required</h2>
            </div>
            
            <div style="background-color: #f0f8f5; padding: 30px; border-radius: 10px; text-align: center;">
              <p style="font-size: 16px; color: #333; margin-bottom: 20px;">
                Thank you for signing up! Please verify your email address using the code below:
              </p>
              
              <div style="background-color: #00412E; color: white; font-size: 32px; font-weight: bold; padding: 20px; border-radius: 8px; letter-spacing: 4px; margin: 20px 0;">
                ${code}
              </div>
              
              <p style="font-size: 14px; color: #666; margin-top: 20px;">
                This verification code will expire in 10 minutes.
              </p>
              
              <p style="font-size: 16px; color: #333; margin-top: 25px;">
                Once verified, you'll be able to access all features of Scan2Suggest!
              </p>
            </div>
            
            <div style="margin-top: 30px; padding-top: 20px; border-top: 1px solid #eee; text-align: center;">
              <p style="font-size: 12px; color: #999;">
                If you didn't create an account with us, please ignore this email.
              </p>
              <p style="font-size: 12px; color: #999;">
                This is an automated message, please do not reply.
              </p>
            </div>
          </div>
        `
      };

      const info = await this.transporter.sendMail(mailOptions);
      console.log(`📧 [EMAIL SERVICE] Email verification code sent to ${email}`);
      
      return { 
        success: true, 
        message: 'Email verification code sent successfully',
        messageId: info.messageId 
      };

    } catch (error) {
      console.error('📧 [EMAIL SERVICE] Error sending email verification:', error);
      
      // Fallback to console logging if email fails
      console.log(`📧 [EMAIL SERVICE] FALLBACK - Email verification code for ${email}: ${code}`);
      
      return { 
        success: true, // Still return success so the flow continues
        message: 'Email service unavailable, code logged to console',
        fallback: true 
      };
    }
  }

  
  async sendVerificationCode(email, code) {
    return this.sendPasswordResetCode(email, code);
  }

  async testConnection() {
    if (!this.transporter) {
      return { success: false, message: 'No email transporter configured' };
    }

    try {
      await this.transporter.verify();
      return { success: true, message: 'Email service connection successful' };
    } catch (error) {
      return { success: false, message: `Email service connection failed: ${error.message}` };
    }
  }

  async sendTestEmail(email) {
    try {
      if (!this.transporter) {
        console.log(`📧 [EMAIL SERVICE] Test email would be sent to ${email} (development mode)`);
        return { success: true, message: 'Test email logged to console (development mode)' };
      }

      const mailOptions = {
        from: process.env.EMAIL_USER,
        to: email,
        subject: 'Scan2Suggest - Email Service Test',
        html: `
          <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
            <div style="text-align: center; margin-bottom: 30px;">
              <h1 style="color: #00412E; margin-bottom: 10px;">Scan2Suggest</h1>
              <h2 style="color: #666; font-weight: normal;">Email Service Test</h2>
            </div>
            
            <div style="background-color: #f0f8f5; padding: 30px; border-radius: 10px; text-align: center;">
              <p style="font-size: 16px; color: #333; margin-bottom: 20px;">
                🎉 Congratulations! Your email service is working correctly.
              </p>
              
              <p style="font-size: 14px; color: #666; margin-top: 20px;">
                This test email confirms that:
              </p>
              <ul style="text-align: left; color: #666; margin: 20px 0;">
                <li>✅ SMTP connection is working</li>
                <li>✅ Email authentication is successful</li>
                <li>✅ Email delivery is functional</li>
              </ul>
              
              <p style="font-size: 16px; color: #333; margin-top: 25px;">
                Your Scan2Suggest app can now send verification emails and password reset codes!
              </p>
            </div>
            
            <div style="margin-top: 30px; padding-top: 20px; border-top: 1px solid #eee; text-align: center;">
              <p style="font-size: 12px; color: #999;">
                This is a test email from Scan2Suggest email service.
              </p>
            </div>
          </div>
        `
      };

      const info = await this.transporter.sendMail(mailOptions);
      console.log(`📧 [EMAIL SERVICE] Test email sent to ${email}`);
      
      return { 
        success: true, 
        message: 'Test email sent successfully',
        messageId: info.messageId 
      };

    } catch (error) {
      console.error('📧 [EMAIL SERVICE] Error sending test email:', error);
      
      return { 
        success: false, 
        message: `Failed to send test email: ${error.message}`,
        error: error.message
      };
    }
  }
}

module.exports = new EmailService();
