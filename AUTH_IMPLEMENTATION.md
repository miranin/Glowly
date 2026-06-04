# Authentication Implementation Guide

Complete code examples for implementing authentication endpoints for the Glowly backend.

## Technology Stack Used
- Node.js + Express
- PostgreSQL
- JWT for tokens
- bcrypt for password hashing

---

## Installation

```bash
npm install express cors helmet dotenv
npm install bcrypt jsonwebtoken
npm install pg
npm install express-validator
npm install express-rate-limit
```

---

## Complete Authentication Controller

### File: `src/controllers/authController.js`

```javascript
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const { validationResult } = require('express-validator');
const db = require('../config/database');
const otpService = require('../services/otpService');
const emailService = require('../services/emailService');
const smsService = require('../services/smsService');

// ===== REGISTER =====
exports.register = async (req, res) => {
  try {
    // Validate input
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { email, username, phoneNumber, password } = req.body;

    // Check if user already exists
    const existingUser = await db.query(
      'SELECT id FROM users WHERE email = $1 OR username = $2 OR phone_number = $3',
      [email, username, phoneNumber]
    );

    if (existingUser.rows.length > 0) {
      return res.status(400).json({
        message: 'User with this email, username, or phone already exists'
      });
    }

    // Hash password
    const passwordHash = await bcrypt.hash(password, 10);

    // Create user
    const result = await db.query(
      `INSERT INTO users (email, username, phone_number, password_hash, auth_provider)
       VALUES ($1, $2, $3, $4, $5)
       RETURNING id, email, username, created_at`,
      [email, username, phoneNumber, passwordHash, 'email']
    );

    const user = result.rows[0];

    // Generate tokens
    const accessToken = generateAccessToken(user.id, email);
    const refreshToken = generateRefreshToken(user.id);

    // Store refresh token
    await storeRefreshToken(user.id, refreshToken);

    // Send verification email
    const verificationToken = await createEmailVerificationToken(user.id);
    await emailService.sendVerificationEmail(email, verificationToken);

    // Response
    res.status(201).json({
      accessToken,
      refreshToken,
      tokenType: 'Bearer',
      username: user.username,
      email: user.email,
      roles: ['USER']
    });

  } catch (error) {
    console.error('Registration error:', error);
    res.status(500).json({ message: 'Server error during registration' });
  }
};

// ===== LOGIN =====
exports.login = async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { usernameOrEmail, password } = req.body;

    // Find user (email, username, or phone)
    const result = await db.query(
      `SELECT id, email, username, password_hash, is_premium, auth_provider
       FROM users
       WHERE (email = $1 OR username = $1 OR phone_number = $1)
       AND deleted_at IS NULL`,
      [usernameOrEmail]
    );

    if (result.rows.length === 0) {
      return res.status(401).json({ message: 'Invalid credentials' });
    }

    const user = result.rows[0];

    // Verify password
    const isValidPassword = await bcrypt.compare(password, user.password_hash);
    if (!isValidPassword) {
      return res.status(401).json({ message: 'Invalid credentials' });
    }

    // Update last login
    await db.query(
      'UPDATE users SET last_login_at = CURRENT_TIMESTAMP WHERE id = $1',
      [user.id]
    );

    // Generate tokens
    const accessToken = generateAccessToken(user.id, user.email);
    const refreshToken = generateRefreshToken(user.id);

    // Store refresh token
    await storeRefreshToken(user.id, refreshToken);

    // Determine roles
    const roles = ['USER'];
    if (user.is_premium) roles.push('PREMIUM_USER');

    res.json({
      accessToken,
      refreshToken,
      tokenType: 'Bearer',
      username: user.username,
      email: user.email,
      roles
    });

  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ message: 'Server error during login' });
  }
};

// ===== LOGOUT =====
exports.logout = async (req, res) => {
  try {
    const userId = req.userId; // From auth middleware

    // Revoke all refresh tokens for user
    await db.query(
      'UPDATE refresh_tokens SET revoked_at = CURRENT_TIMESTAMP WHERE user_id = $1',
      [userId]
    );

    res.json({ message: 'Logged out successfully' });

  } catch (error) {
    console.error('Logout error:', error);
    res.status(500).json({ message: 'Server error during logout' });
  }
};

// ===== REFRESH TOKEN =====
exports.refreshToken = async (req, res) => {
  try {
    const { refreshToken } = req.body;

    if (!refreshToken) {
      return res.status(400).json({ message: 'Refresh token required' });
    }

    // Verify refresh token
    let decoded;
    try {
      decoded = jwt.verify(refreshToken, process.env.JWT_REFRESH_SECRET);
    } catch (err) {
      return res.status(401).json({ message: 'Invalid or expired refresh token' });
    }

    // Check if token exists and not revoked
    const result = await db.query(
      `SELECT user_id, expires_at FROM refresh_tokens
       WHERE token = $1 AND revoked_at IS NULL`,
      [refreshToken]
    );

    if (result.rows.length === 0) {
      return res.status(401).json({ message: 'Invalid refresh token' });
    }

    const tokenData = result.rows[0];

    // Check if expired
    if (new Date(tokenData.expires_at) < new Date()) {
      return res.status(401).json({ message: 'Refresh token expired' });
    }

    // Get user email
    const userResult = await db.query(
      'SELECT email FROM users WHERE id = $1',
      [decoded.userId]
    );

    if (userResult.rows.length === 0) {
      return res.status(404).json({ message: 'User not found' });
    }

    // Generate new tokens
    const newAccessToken = generateAccessToken(decoded.userId, userResult.rows[0].email);
    const newRefreshToken = generateRefreshToken(decoded.userId);

    // Revoke old refresh token
    await db.query(
      'UPDATE refresh_tokens SET revoked_at = CURRENT_TIMESTAMP WHERE token = $1',
      [refreshToken]
    );

    // Store new refresh token
    await storeRefreshToken(decoded.userId, newRefreshToken);

    res.json({
      token: newAccessToken,
      refreshToken: newRefreshToken
    });

  } catch (error) {
    console.error('Refresh token error:', error);
    res.status(500).json({ message: 'Server error during token refresh' });
  }
};

// ===== VERIFY OTP =====
exports.verifyOtp = async (req, res) => {
  try {
    const { identifier, otpCode } = req.body;

    const isValid = await otpService.verifyOTP(identifier, otpCode);

    if (!isValid) {
      return res.status(400).json({
        message: 'Invalid or expired OTP code',
        verified: false
      });
    }

    // Mark user as verified
    if (identifier.includes('@')) {
      // Email
      await db.query(
        'UPDATE users SET is_email_verified = TRUE WHERE email = $1',
        [identifier]
      );
    } else {
      // Phone
      await db.query(
        'UPDATE users SET is_phone_verified = TRUE WHERE phone_number = $1',
        [identifier]
      );
    }

    res.json({
      message: 'Verification successful',
      verified: true,
      identifier
    });

  } catch (error) {
    console.error('OTP verification error:', error);
    res.status(500).json({ message: 'Server error during OTP verification' });
  }
};

// ===== RESEND OTP =====
exports.resendOtp = async (req, res) => {
  try {
    const { identifier } = req.body;

    // Check rate limit
    await otpService.checkOTPRateLimit(identifier);

    // Generate new OTP
    const otpCode = await otpService.createOTP(identifier);

    // Send OTP
    if (identifier.includes('@')) {
      // Email
      await emailService.sendOTP(identifier, otpCode);
    } else {
      // SMS
      await smsService.sendOTP(identifier, otpCode);
    }

    // Mask identifier
    const maskedIdentifier = maskIdentifier(identifier);

    res.json({
      message: 'OTP sent successfully',
      identifier,
      maskedIdentifier,
      expiresIn: 600 // 10 minutes
    });

  } catch (error) {
    if (error.message.includes('Too many')) {
      return res.status(429).json({ message: error.message });
    }
    console.error('Resend OTP error:', error);
    res.status(500).json({ message: 'Server error during OTP resend' });
  }
};

// ===== FORGOT PASSWORD =====
exports.forgotPassword = async (req, res) => {
  try {
    const { email } = req.body;

    // Find user
    const result = await db.query(
      'SELECT id FROM users WHERE email = $1 AND deleted_at IS NULL',
      [email]
    );

    // Always return success (don't reveal if email exists)
    if (result.rows.length === 0) {
      return res.json({
        message: 'If the email exists, a password reset link has been sent'
      });
    }

    const userId = result.rows[0].id;

    // Generate reset token
    const resetToken = await createPasswordResetToken(userId);

    // Send email with reset link
    const resetLink = `${process.env.FRONTEND_URL}/reset-password?token=${resetToken}`;
    await emailService.sendPasswordResetEmail(email, resetLink);

    res.json({
      message: 'If the email exists, a password reset link has been sent'
    });

  } catch (error) {
    console.error('Forgot password error:', error);
    res.status(500).json({ message: 'Server error processing request' });
  }
};

// ===== RESET PASSWORD =====
exports.resetPassword = async (req, res) => {
  try {
    const { token, newPassword } = req.body;

    // Validate token
    const result = await db.query(
      `SELECT user_id, expires_at, used FROM password_reset_tokens
       WHERE token = $1`,
      [token]
    );

    if (result.rows.length === 0) {
      return res.status(400).json({ message: 'Invalid reset token' });
    }

    const tokenData = result.rows[0];

    if (tokenData.used) {
      return res.status(400).json({ message: 'Reset token already used' });
    }

    if (new Date(tokenData.expires_at) < new Date()) {
      return res.status(400).json({ message: 'Reset token expired' });
    }

    // Hash new password
    const passwordHash = await bcrypt.hash(newPassword, 10);

    // Update password
    await db.query(
      'UPDATE users SET password_hash = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2',
      [passwordHash, tokenData.user_id]
    );

    // Mark token as used
    await db.query(
      'UPDATE password_reset_tokens SET used = TRUE WHERE token = $1',
      [token]
    );

    // Revoke all refresh tokens for security
    await db.query(
      'UPDATE refresh_tokens SET revoked_at = CURRENT_TIMESTAMP WHERE user_id = $1',
      [tokenData.user_id]
    );

    res.json({ message: 'Password reset successful' });

  } catch (error) {
    console.error('Reset password error:', error);
    res.status(500).json({ message: 'Server error during password reset' });
  }
};

// ===== VERIFY EMAIL =====
exports.verifyEmail = async (req, res) => {
  try {
    const { token } = req.body;

    // Validate token
    const result = await db.query(
      `SELECT user_id, expires_at, verified FROM email_verification_tokens
       WHERE token = $1`,
      [token]
    );

    if (result.rows.length === 0) {
      return res.status(400).json({ message: 'Invalid verification token' });
    }

    const tokenData = result.rows[0];

    if (tokenData.verified) {
      return res.status(400).json({ message: 'Email already verified' });
    }

    if (new Date(tokenData.expires_at) < new Date()) {
      return res.status(400).json({ message: 'Verification token expired' });
    }

    // Mark email as verified
    await db.query(
      'UPDATE users SET is_email_verified = TRUE WHERE id = $1',
      [tokenData.user_id]
    );

    // Mark token as verified
    await db.query(
      'UPDATE email_verification_tokens SET verified = TRUE WHERE token = $1',
      [token]
    );

    res.json({ message: 'Email verified successfully' });

  } catch (error) {
    console.error('Email verification error:', error);
    res.status(500).json({ message: 'Server error during email verification' });
  }
};

// ===== HELPER FUNCTIONS =====

function generateAccessToken(userId, email) {
  return jwt.sign(
    { userId, email },
    process.env.JWT_SECRET,
    { expiresIn: process.env.JWT_EXPIRES_IN || '15m' }
  );
}

function generateRefreshToken(userId) {
  return jwt.sign(
    { userId },
    process.env.JWT_REFRESH_SECRET,
    { expiresIn: process.env.JWT_REFRESH_EXPIRES_IN || '7d' }
  );
}

async function storeRefreshToken(userId, token) {
  const expiresAt = new Date();
  expiresAt.setDate(expiresAt.getDate() + 7); // 7 days

  await db.query(
    `INSERT INTO refresh_tokens (user_id, token, expires_at)
     VALUES ($1, $2, $3)`,
    [userId, token, expiresAt]
  );
}

async function createPasswordResetToken(userId) {
  const crypto = require('crypto');
  const token = crypto.randomBytes(32).toString('hex');
  const expiresAt = new Date();
  expiresAt.setHours(expiresAt.getHours() + 1); // 1 hour

  await db.query(
    `INSERT INTO password_reset_tokens (user_id, token, expires_at)
     VALUES ($1, $2, $3)`,
    [userId, token, expiresAt]
  );

  return token;
}

async function createEmailVerificationToken(userId) {
  const crypto = require('crypto');
  const token = crypto.randomBytes(32).toString('hex');
  const expiresAt = new Date();
  expiresAt.setDate(expiresAt.getDate() + 7); // 7 days

  await db.query(
    `INSERT INTO email_verification_tokens (user_id, token, expires_at)
     VALUES ($1, $2, $3)`,
    [userId, token, expiresAt]
  );

  return token;
}

function maskIdentifier(identifier) {
  if (identifier.includes('@')) {
    // Email: test@example.com -> te**@example.com
    const [local, domain] = identifier.split('@');
    return `${local.substring(0, 2)}${'*'.repeat(local.length - 2)}@${domain}`;
  } else {
    // Phone: +77001234567 -> +7700***4567
    return identifier.substring(0, 5) + '***' + identifier.substring(identifier.length - 4);
  }
}

module.exports = exports;
```

---

## Authentication Middleware

### File: `src/middleware/auth.js`

```javascript
const jwt = require('jsonwebtoken');
const db = require('../config/database');

exports.authenticateToken = async (req, res, next) => {
  try {
    // Get token from header
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1]; // Bearer TOKEN

    if (!token) {
      return res.status(401).json({ message: 'Access token required' });
    }

    // Verify token
    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    // Check if user exists
    const result = await db.query(
      'SELECT id, email, is_premium FROM users WHERE id = $1 AND deleted_at IS NULL',
      [decoded.userId]
    );

    if (result.rows.length === 0) {
      return res.status(401).json({ message: 'User not found' });
    }

    // Attach user info to request
    req.userId = decoded.userId;
    req.userEmail = decoded.email;
    req.isPremium = result.rows[0].is_premium;

    next();

  } catch (error) {
    if (error.name === 'JsonWebTokenError') {
      return res.status(401).json({ message: 'Invalid token' });
    }
    if (error.name === 'TokenExpiredError') {
      return res.status(401).json({ message: 'Token expired' });
    }
    console.error('Auth middleware error:', error);
    res.status(500).json({ message: 'Server error during authentication' });
  }
};

exports.requirePremium = (req, res, next) => {
  if (!req.isPremium) {
    return res.status(403).json({
      message: 'Premium subscription required',
      upgradeTo: 'premium'
    });
  }
  next();
};
```

---

## Routes

### File: `src/routes/auth.js`

```javascript
const express = require('express');
const { body } = require('express-validator');
const rateLimit = require('express-rate-limit');
const authController = require('../controllers/authController');

const router = express.Router();

// Rate limiters
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 5,
  message: 'Too many attempts, please try again later'
});

const otpLimiter = rateLimit({
  windowMs: 60 * 60 * 1000, // 1 hour
  max: 3,
  message: 'Too many OTP requests, please try again later'
});

// Validation rules
const registerValidation = [
  body('email').isEmail().normalizeEmail(),
  body('username').isLength({ min: 3, max: 30 }).isAlphanumeric(),
  body('phoneNumber').matches(/^\+?[1-9]\d{1,14}$/),
  body('password').isLength({ min: 8 })
];

const loginValidation = [
  body('usernameOrEmail').notEmpty(),
  body('password').notEmpty()
];

// Routes
router.post('/register', registerValidation, authController.register);
router.post('/login', authLimiter, loginValidation, authController.login);
router.post('/logout', authController.logout);
router.post('/refresh', authController.refreshToken);
router.post('/verify-otp', authController.verifyOtp);
router.post('/resend-otp', otpLimiter, authController.resendOtp);
router.post('/forgot-password', authLimiter, authController.forgotPassword);
router.post('/reset-password', authController.resetPassword);
router.post('/verify-email', authController.verifyEmail);

module.exports = router;
```

---

## OTP Service

### File: `src/services/otpService.js`

```javascript
const crypto = require('crypto');
const db = require('../config/database');

// Generate 6-digit OTP
function generateOTP() {
  return crypto.randomInt(100000, 999999).toString();
}

// Create OTP and store in database
exports.createOTP = async (identifier) => {
  const code = generateOTP();
  const expiresAt = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes

  await db.query(
    `INSERT INTO otp_codes (identifier, code, expires_at, attempts)
     VALUES ($1, $2, $3, 0)
     ON CONFLICT (identifier)
     DO UPDATE SET code = $2, expires_at = $3, attempts = 0, verified = FALSE`,
    [identifier, code, expiresAt]
  );

  return code;
};

// Verify OTP
exports.verifyOTP = async (identifier, code) => {
  const result = await db.query(
    `SELECT * FROM otp_codes
     WHERE identifier = $1 AND code = $2 AND expires_at > NOW() AND verified = FALSE`,
    [identifier, code]
  );

  if (result.rows.length === 0) {
    // Increment failed attempts
    await db.query(
      'UPDATE otp_codes SET attempts = attempts + 1 WHERE identifier = $1',
      [identifier]
    );
    return false;
  }

  // Mark as verified and delete
  await db.query(
    'DELETE FROM otp_codes WHERE identifier = $1',
    [identifier]
  );

  return true;
};

// Check rate limit
exports.checkOTPRateLimit = async (identifier) => {
  const result = await db.query(
    `SELECT COUNT(*) as count FROM otp_requests
     WHERE identifier = $1 AND created_at > NOW() - INTERVAL '1 hour'`,
    [identifier]
  );

  if (parseInt(result.rows[0].count) >= 3) {
    throw new Error('Too many OTP requests. Please try again in an hour.');
  }

  await db.query(
    'INSERT INTO otp_requests (identifier, created_at) VALUES ($1, NOW())',
    [identifier]
  );
};

module.exports = exports;
```

---

## Testing

### Test with cURL

```bash
# Register
curl -X POST http://localhost:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "username": "testuser",
    "phoneNumber": "+77001234567",
    "password": "password123"
  }'

# Login
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "usernameOrEmail": "test@example.com",
    "password": "password123"
  }'

# Use token (replace TOKEN with actual token)
curl http://localhost:8080/api/users/me \
  -H "Authorization: Bearer TOKEN"

# Refresh token
curl -X POST http://localhost:8080/api/auth/refresh \
  -H "Content-Type: application/json" \
  -d '{
    "refreshToken": "YOUR_REFRESH_TOKEN"
  }'
```

---

**Created:** 2024-01-15
**Last Updated:** 2024-01-15
