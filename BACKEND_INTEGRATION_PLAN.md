# Backend Integration Plan for Glowly

This document provides a complete, step-by-step plan for implementing the backend infrastructure for the Glowly iOS application.

## Table of Contents
1. [Overview](#overview)
2. [Server Infrastructure Setup](#server-infrastructure-setup)
3. [SMS Service Integration](#sms-service-integration)
4. [API Implementation Guide](#api-implementation-guide)
5. [Database Schema](#database-schema)
6. [Security Implementation](#security-implementation)
7. [Testing & Deployment](#testing--deployment)
8. [Cost Estimates](#cost-estimates)

---

## Overview

### What You Need
1. **Server** - Virtual Private Server (VPS) to host your backend API
2. **SMS Service** - Third-party service for sending OTP codes via SMS
3. **Email Service** - For sending verification emails and password resets
4. **File Storage** - For product images and user-uploaded media
5. **Database** - PostgreSQL or MySQL for data persistence

### Current Status
- ✅ iOS app network layer: 100% complete
- ✅ API endpoints defined: 100% complete
- ✅ Request/response models: 100% complete
- ❌ Backend API: Not implemented
- ❌ Database: Not set up
- ❌ Server: Not rented

---

## Server Infrastructure Setup

### Step 1: Choose a Server Provider

#### Recommended Options

**Option A: DigitalOcean (Recommended for Beginners)**
- **Cost:** $6-12/month
- **Why:** Easy setup, good documentation, managed databases available
- **Plan:** Basic Droplet (1GB RAM, 25GB SSD)
- **Website:** https://www.digitalocean.com

**Option B: Linode (Akamai)**
- **Cost:** $5-10/month
- **Why:** Reliable, good performance
- **Plan:** Nanode 1GB
- **Website:** https://www.linode.com

**Option C: Hetzner**
- **Cost:** €4-8/month (~$4-9/month)
- **Why:** Best price/performance ratio, EU-based
- **Plan:** CX11 or CX21
- **Website:** https://www.hetzner.com/cloud

**Option D: AWS Lightsail**
- **Cost:** $5-10/month
- **Why:** Part of AWS ecosystem, scalable
- **Plan:** $5/month instance
- **Website:** https://aws.amazon.com/lightsail/

### Step 2: Rent and Configure Your Server

#### 2.1 Create Account and Purchase Server
```bash
# Example: DigitalOcean Setup
1. Go to digitalocean.com
2. Create account (use GitHub account for $200 free credit)
3. Click "Create" → "Droplets"
4. Choose:
   - Image: Ubuntu 24.04 LTS
   - Plan: Basic ($6/month - 1GB RAM)
   - Datacenter: Closest to your users (e.g., Frankfurt for EU, NYC for US)
   - Authentication: SSH key (recommended) or password
5. Click "Create Droplet"
6. Wait 1-2 minutes for server creation
7. Note your server IP address (e.g., 172.234.116.129)
```

#### 2.2 Connect to Your Server
```bash
# From your Mac terminal
ssh root@YOUR_SERVER_IP

# If using SSH key
ssh -i ~/.ssh/id_rsa root@YOUR_SERVER_IP

# First time: Type 'yes' to accept fingerprint
```

#### 2.3 Initial Server Setup
```bash
# Update system
apt update && apt upgrade -y

# Create non-root user (replace 'glowly' with your username)
adduser glowly
usermod -aG sudo glowly

# Switch to new user
su - glowly

# Install required software
sudo apt install -y curl git build-essential

# Install Node.js (for Node backend) or Python (for Python backend)
# For Node.js:
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs

# For Python:
sudo apt install -y python3 python3-pip python3-venv

# Install PostgreSQL database
sudo apt install -y postgresql postgresql-contrib

# Install Nginx (web server/reverse proxy)
sudo apt install -y nginx

# Install Certbot (for SSL certificates)
sudo apt install -y certbot python3-certbot-nginx
```

### Step 3: Choose Backend Technology Stack

#### Option A: Node.js + Express (Recommended)
**Pros:** Fast development, JavaScript everywhere, large ecosystem
**Cons:** Single-threaded (use clustering for production)

```bash
# Create project directory
mkdir ~/glowly-backend
cd ~/glowly-backend

# Initialize Node.js project
npm init -y

# Install dependencies
npm install express cors helmet dotenv bcrypt jsonwebtoken
npm install pg pg-hstore sequelize  # For PostgreSQL
npm install multer  # For file uploads
npm install nodemailer  # For emails
npm install express-validator  # For input validation
npm install express-rate-limit  # For rate limiting

# Install dev dependencies
npm install --save-dev nodemon typescript @types/node @types/express
```

#### Option B: Python + FastAPI
**Pros:** Great for AI integration, type safety, automatic API docs
**Cons:** Slightly slower than Node.js

```bash
# Create project directory
mkdir ~/glowly-backend
cd ~/glowly-backend

# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install fastapi uvicorn[standard]
pip install sqlalchemy psycopg2-binary
pip install python-jose[cryptography] passlib[bcrypt]
pip install python-multipart  # For file uploads
pip install pydantic pydantic-settings
pip install alembic  # Database migrations
pip install python-dotenv
```

#### Option C: Go + Gin/Fiber
**Pros:** Extremely fast, compiled, excellent concurrency
**Cons:** Steeper learning curve, less flexible

```bash
# Install Go
wget https://go.dev/dl/go1.21.5.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.21.5.linux-amd64.tar.gz
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
source ~/.bashrc

# Create project
mkdir ~/glowly-backend
cd ~/glowly-backend
go mod init glowly-backend

# Install dependencies
go get github.com/gin-gonic/gin
go get github.com/lib/pq
go get github.com/golang-jwt/jwt/v5
go get golang.org/x/crypto/bcrypt
```

### Step 4: Set Up Database

#### 4.1 Configure PostgreSQL
```bash
# Switch to postgres user
sudo -u postgres psql

# In PostgreSQL console, create database and user:
CREATE DATABASE glowly_db;
CREATE USER glowly_user WITH ENCRYPTED PASSWORD 'your_secure_password_here';
GRANT ALL PRIVILEGES ON DATABASE glowly_db TO glowly_user;
\q

# Allow local connections (edit pg_hba.conf)
sudo nano /etc/postgresql/16/main/pg_hba.conf

# Add this line:
# local   glowly_db    glowly_user                     md5

# Restart PostgreSQL
sudo systemctl restart postgresql
```

#### 4.2 Test Database Connection
```bash
psql -U glowly_user -d glowly_db -h localhost
# Enter password when prompted
# If connected successfully, type \q to exit
```

### Step 5: Configure Domain (Optional but Recommended)

#### 5.1 Purchase Domain
- **Namecheap:** ~$10/year (.com domain)
- **Cloudflare:** ~$10/year + free DNS/CDN
- **GoDaddy:** ~$15/year

#### 5.2 Point Domain to Server
```
1. Go to your domain registrar's DNS settings
2. Create an A record:
   - Type: A
   - Name: @ (for api.glowly.app) or 'api' (for api.glowly.app)
   - Value: YOUR_SERVER_IP
   - TTL: 300 (5 minutes)

3. Wait 5-30 minutes for DNS propagation

4. Test:
   ping api.glowly.app
   # Should show your server IP
```

#### 5.3 Set Up SSL Certificate (Free with Let's Encrypt)
```bash
# For domain api.glowly.app
sudo certbot --nginx -d api.glowly.app

# Follow prompts:
# - Enter email address
# - Agree to terms
# - Choose redirect HTTP to HTTPS (option 2)

# Certificate auto-renews every 90 days
# Test auto-renewal:
sudo certbot renew --dry-run
```

---

## SMS Service Integration

### Step 1: Choose SMS Provider

#### Recommended Options for Kazakhstan/Russia/International

**Option A: Twilio (Recommended - Global Coverage)**
- **Cost:** Pay-as-you-go, ~$0.05 per SMS
- **Pros:** Reliable, works globally, great docs
- **Cons:** Slightly expensive for high volume
- **Signup:** https://www.twilio.com/try-twilio
- **Free Trial:** $15 credit

**Setup:**
```bash
# After signup, get credentials:
# - Account SID
# - Auth Token
# - Phone Number (you get one free number)

# Install SDK (Node.js example)
npm install twilio

# Example code:
const twilio = require('twilio');
const client = twilio(ACCOUNT_SID, AUTH_TOKEN);

async function sendOTP(phoneNumber, otpCode) {
  await client.messages.create({
    body: `Your Glowly verification code is: ${otpCode}`,
    from: '+1234567890',  // Your Twilio number
    to: phoneNumber
  });
}
```

**Option B: SMS.RU (Best for Russia/Kazakhstan)**
- **Cost:** ~1-2 RUB per SMS (~$0.01-0.02)
- **Pros:** Cheapest for CIS countries, easy integration
- **Cons:** Limited to CIS region
- **Signup:** https://sms.ru/
- **Free Trial:** 50 SMS

**Setup:**
```bash
# Get API key from dashboard

# Example code (Node.js):
const axios = require('axios');

async function sendOTP(phoneNumber, otpCode) {
  const apiKey = 'YOUR_API_KEY';
  const url = `https://sms.ru/sms/send`;

  await axios.post(url, {
    api_id: apiKey,
    to: phoneNumber,
    msg: `Ваш код подтверждения Glowly: ${otpCode}`,
    json: 1
  });
}
```

**Option C: MessageBird (Good Balance)**
- **Cost:** ~$0.04 per SMS
- **Pros:** Good coverage, reliable
- **Signup:** https://www.messagebird.com/
- **Free Trial:** $10 credit

**Option D: Amazon SNS (If using AWS)**
- **Cost:** $0.00645 per SMS (US), varies by region
- **Pros:** Integrated with AWS, scalable
- **Cons:** Requires AWS account

### Step 2: Implement OTP System

#### 2.1 OTP Generation and Storage
```javascript
// Node.js example
const crypto = require('crypto');

// Generate 6-digit OTP
function generateOTP() {
  return crypto.randomInt(100000, 999999).toString();
}

// Store in database with expiry
async function createOTP(identifier) {
  const code = generateOTP();
  const expiresAt = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes

  await db.query(`
    INSERT INTO otp_codes (identifier, code, expires_at, attempts)
    VALUES ($1, $2, $3, 0)
    ON CONFLICT (identifier)
    DO UPDATE SET code = $2, expires_at = $3, attempts = 0
  `, [identifier, code, expiresAt]);

  return code;
}

// Verify OTP
async function verifyOTP(identifier, code) {
  const result = await db.query(`
    SELECT * FROM otp_codes
    WHERE identifier = $1 AND code = $2 AND expires_at > NOW()
  `, [identifier, code]);

  if (result.rows.length === 0) {
    // Increment failed attempts
    await db.query(`
      UPDATE otp_codes SET attempts = attempts + 1
      WHERE identifier = $1
    `, [identifier]);
    return false;
  }

  // Delete OTP after successful verification
  await db.query(`DELETE FROM otp_codes WHERE identifier = $1`, [identifier]);
  return true;
}
```

#### 2.2 Rate Limiting for OTP Requests
```javascript
// Prevent abuse - max 3 OTP requests per hour per identifier
async function checkOTPRateLimit(identifier) {
  const result = await db.query(`
    SELECT COUNT(*) as count FROM otp_requests
    WHERE identifier = $1 AND created_at > NOW() - INTERVAL '1 hour'
  `, [identifier]);

  if (result.rows[0].count >= 3) {
    throw new Error('Too many OTP requests. Please try again later.');
  }

  await db.query(`
    INSERT INTO otp_requests (identifier, created_at) VALUES ($1, NOW())
  `, [identifier]);
}
```

### Step 3: Email Service Setup (Alternative to SMS)

#### Recommended: SendGrid (Free tier: 100 emails/day)
```bash
# Signup: https://sendgrid.com/
# Get API key from dashboard

npm install @sendgrid/mail

# Example code:
const sgMail = require('@sendgrid/mail');
sgMail.setApiKey(process.env.SENDGRID_API_KEY);

async function sendVerificationEmail(email, otpCode) {
  const msg = {
    to: email,
    from: 'noreply@glowly.app',
    subject: 'Verify your Glowly account',
    text: `Your verification code is: ${otpCode}`,
    html: `<strong>Your verification code is: ${otpCode}</strong>`,
  };

  await sgMail.send(msg);
}
```

**Alternatives:**
- **Mailgun** - 5,000 emails/month free
- **AWS SES** - $0.10 per 1,000 emails
- **Resend** - 3,000 emails/month free

---

## API Implementation Guide

### Step 1: Project Structure

#### Node.js + Express Structure
```
glowly-backend/
├── src/
│   ├── config/
│   │   ├── database.js
│   │   ├── auth.js
│   │   └── env.js
│   ├── models/
│   │   ├── User.js
│   │   ├── UserProfile.js
│   │   ├── Product.js
│   │   ├── Post.js
│   │   ├── Comment.js
│   │   └── WishList.js
│   ├── controllers/
│   │   ├── authController.js
│   │   ├── userController.js
│   │   ├── productController.js
│   │   ├── postController.js
│   │   └── wishlistController.js
│   ├── middleware/
│   │   ├── auth.js
│   │   ├── validation.js
│   │   ├── errorHandler.js
│   │   └── rateLimit.js
│   ├── routes/
│   │   ├── auth.js
│   │   ├── users.js
│   │   ├── products.js
│   │   ├── posts.js
│   │   └── wishlist.js
│   ├── services/
│   │   ├── smsService.js
│   │   ├── emailService.js
│   │   ├── otpService.js
│   │   └── uploadService.js
│   ├── utils/
│   │   ├── logger.js
│   │   └── helpers.js
│   └── app.js
├── .env
├── .env.example
├── package.json
└── README.md
```

### Step 2: Environment Configuration

#### .env.example (Template)
```bash
# Server
NODE_ENV=development
PORT=8080
API_VERSION=v1

# Database
DB_HOST=localhost
DB_PORT=5432
DB_NAME=glowly_db
DB_USER=glowly_user
DB_PASSWORD=your_secure_password

# JWT Tokens
JWT_SECRET=your_jwt_secret_key_change_this_in_production_min_32_chars
JWT_REFRESH_SECRET=your_refresh_secret_key_change_this_too
JWT_EXPIRES_IN=15m
JWT_REFRESH_EXPIRES_IN=7d

# SMS Service (Choose one)
SMS_PROVIDER=twilio  # or sms_ru, messagebird
TWILIO_ACCOUNT_SID=your_account_sid
TWILIO_AUTH_TOKEN=your_auth_token
TWILIO_PHONE_NUMBER=+1234567890

# Email Service
SENDGRID_API_KEY=your_sendgrid_api_key
FROM_EMAIL=noreply@glowly.app

# File Upload
UPLOAD_DIR=./uploads
MAX_FILE_SIZE=10485760  # 10MB in bytes

# Rate Limiting
RATE_LIMIT_WINDOW=15  # minutes
RATE_LIMIT_MAX_REQUESTS=100

# CORS
ALLOWED_ORIGINS=http://localhost:3000,https://glowly.app

# Logging
LOG_LEVEL=info
```

### Step 3: Implement Core Authentication

See [AUTH_IMPLEMENTATION.md](AUTH_IMPLEMENTATION.md) for detailed code examples.

**Key Components:**
1. User registration with password hashing
2. Login with JWT token generation
3. Token refresh mechanism
4. OTP generation and verification
5. Password reset flow
6. Email verification

### Step 4: Implement Data Models

See [DATABASE_SCHEMA.md](DATABASE_SCHEMA.md) for complete schema.

### Step 5: Implement File Upload

```javascript
// Using multer for Node.js
const multer = require('multer');
const path = require('path');
const crypto = require('crypto');

// Configure storage
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, 'uploads/');
  },
  filename: (req, file, cb) => {
    const uniqueName = crypto.randomBytes(16).toString('hex');
    const ext = path.extname(file.originalname);
    cb(null, `${uniqueName}${ext}`);
  }
});

// File filter
const fileFilter = (req, file, cb) => {
  const allowedTypes = /jpeg|jpg|png|gif|webp/;
  const extname = allowedTypes.test(path.extname(file.originalname).toLowerCase());
  const mimetype = allowedTypes.test(file.mimetype);

  if (mimetype && extname) {
    return cb(null, true);
  }
  cb(new Error('Only image files are allowed'));
};

// Create upload middleware
const upload = multer({
  storage,
  limits: { fileSize: 10 * 1024 * 1024 }, // 10MB
  fileFilter
});

// Use in route
app.post('/api/products/:productId/upload-image',
  authenticateToken,
  upload.single('image'),
  async (req, res) => {
    const imageUrl = `/uploads/${req.file.filename}`;
    // Save imageUrl to database
    res.json({ imageUrl });
  }
);
```

### Step 6: Deploy Backend

#### 6.1 Prepare for Deployment
```bash
# On your local machine, push code to GitHub
git init
git add .
git commit -m "Initial backend implementation"
git branch -M main
git remote add origin https://github.com/yourusername/glowly-backend.git
git push -u origin main
```

#### 6.2 Deploy to Server
```bash
# SSH into server
ssh glowly@YOUR_SERVER_IP

# Clone repository
cd ~
git clone https://github.com/yourusername/glowly-backend.git
cd glowly-backend

# Install dependencies
npm install --production

# Create .env file
nano .env
# Copy contents from .env.example and fill in real values

# Test run
npm start

# Should see: "Server listening on port 8080"
# Press Ctrl+C to stop
```

#### 6.3 Set Up Process Manager (Keep Server Running)
```bash
# Install PM2
sudo npm install -g pm2

# Start application
pm2 start src/app.js --name glowly-api

# Save PM2 configuration
pm2 save

# Set up PM2 to start on boot
pm2 startup
# Follow the command it outputs

# Useful PM2 commands:
pm2 status          # Check status
pm2 logs glowly-api # View logs
pm2 restart glowly-api  # Restart app
pm2 stop glowly-api     # Stop app
```

#### 6.4 Configure Nginx as Reverse Proxy
```bash
# Create Nginx configuration
sudo nano /etc/nginx/sites-available/glowly-api

# Paste this configuration:
server {
    listen 80;
    server_name api.glowly.app;  # Or use your server IP

    location / {
        proxy_pass http://localhost:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}

# Enable site
sudo ln -s /etc/nginx/sites-available/glowly-api /etc/nginx/sites-enabled/

# Test configuration
sudo nginx -t

# Reload Nginx
sudo systemctl reload nginx
```

#### 6.5 Test API
```bash
# From your Mac terminal
curl http://YOUR_SERVER_IP/api/health

# Should return something like:
# {"status":"ok","timestamp":"2024-01-15T10:30:00Z"}
```

### Step 7: Update iOS App Configuration

```swift
// Update NetworkConfiguration.swift
public static let development = NetworkConfiguration(
    baseURL: "http://YOUR_SERVER_IP:8080",  // Or https://api.glowly.app
    enableLogging: true
)

public static let production = NetworkConfiguration(
    baseURL: "https://api.glowly.app",
    enableLogging: false
)
```

---

## Database Schema

### Complete SQL Schema

See [DATABASE_SCHEMA.md](DATABASE_SCHEMA.md) for the complete database schema with all tables, relationships, and indexes.

**Main Tables:**
1. `users` - User accounts
2. `user_profiles` - Onboarding data
3. `products` - Cosmetic products
4. `posts` - Social feed posts
5. `post_media` - Post images/videos
6. `comments` - Post comments
7. `likes` - Post and comment likes
8. `wishlist` - User wishlists
9. `follows` - User follow relationships
10. `otp_codes` - OTP verification
11. `otp_requests` - Rate limiting

---

## Security Implementation

### Essential Security Measures

#### 1. Password Security
```javascript
const bcrypt = require('bcrypt');

// Hash password (on registration)
const hashedPassword = await bcrypt.hash(password, 10);

// Verify password (on login)
const isValid = await bcrypt.compare(password, hashedPassword);
```

#### 2. JWT Token Security
```javascript
const jwt = require('jsonwebtoken');

// Generate access token (short-lived)
const accessToken = jwt.sign(
  { userId, email },
  process.env.JWT_SECRET,
  { expiresIn: '15m' }
);

// Generate refresh token (long-lived)
const refreshToken = jwt.sign(
  { userId },
  process.env.JWT_REFRESH_SECRET,
  { expiresIn: '7d' }
);

// Verify token
const decoded = jwt.verify(token, process.env.JWT_SECRET);
```

#### 3. Input Validation
```javascript
const { body, validationResult } = require('express-validator');

// Validation rules
const registerValidation = [
  body('email').isEmail().normalizeEmail(),
  body('password').isLength({ min: 8 }),
  body('username').isLength({ min: 3, max: 30 }).isAlphanumeric()
];

// Use in route
app.post('/api/auth/register', registerValidation, (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
  }
  // Process registration
});
```

#### 4. Rate Limiting
```javascript
const rateLimit = require('express-rate-limit');

// General API rate limit
const apiLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // Limit each IP to 100 requests per windowMs
  message: 'Too many requests, please try again later.'
});

// Stricter limit for auth endpoints
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 5,
  message: 'Too many login attempts, please try again later.'
});

app.use('/api/', apiLimiter);
app.use('/api/auth/login', authLimiter);
```

#### 5. CORS Configuration
```javascript
const cors = require('cors');

const corsOptions = {
  origin: (origin, callback) => {
    const allowedOrigins = process.env.ALLOWED_ORIGINS.split(',');
    if (!origin || allowedOrigins.includes(origin)) {
      callback(null, true);
    } else {
      callback(new Error('Not allowed by CORS'));
    }
  },
  credentials: true
};

app.use(cors(corsOptions));
```

#### 6. SQL Injection Prevention
```javascript
// ✅ GOOD - Use parameterized queries
const result = await db.query(
  'SELECT * FROM users WHERE email = $1',
  [email]
);

// ❌ BAD - Don't concatenate SQL strings
const result = await db.query(
  `SELECT * FROM users WHERE email = '${email}'`
);
```

#### 7. File Upload Security
```javascript
// Validate file type by magic number, not extension
const fileType = require('file-type');

async function validateImage(buffer) {
  const type = await fileType.fromBuffer(buffer);
  const allowed = ['image/jpeg', 'image/png', 'image/gif'];
  return type && allowed.includes(type.mime);
}
```

---

## Testing & Deployment

### Testing Checklist

#### 1. Local Testing
```bash
# Test all auth endpoints
curl -X POST http://localhost:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123","username":"testuser"}'

curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"usernameOrEmail":"test@example.com","password":"password123"}'

# Test protected endpoints (use token from login)
curl http://localhost:8080/api/users/me \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

#### 2. Integration Testing with iOS App
```swift
// In APITestView.swift (already exists)
1. Update base URL to your server
2. Run test registration
3. Run test login
4. Verify tokens are returned
5. Test token refresh
6. Test OTP flow
```

#### 3. Load Testing (Optional)
```bash
# Install Apache Bench
sudo apt install apache2-utils

# Test 1000 requests with 10 concurrent connections
ab -n 1000 -c 10 http://YOUR_SERVER_IP/api/health
```

### Deployment Checklist

- [ ] Server rented and configured
- [ ] Domain purchased and DNS configured (optional)
- [ ] SSL certificate installed
- [ ] Database created and schema applied
- [ ] Environment variables configured
- [ ] SMS service account created and tested
- [ ] Email service configured
- [ ] File upload directory created with correct permissions
- [ ] PM2 process manager installed and configured
- [ ] Nginx reverse proxy configured
- [ ] Firewall configured (UFW)
- [ ] Backup strategy implemented
- [ ] Monitoring set up (optional: UptimeRobot, Datadog)
- [ ] iOS app updated with production URL
- [ ] All API endpoints tested
- [ ] Rate limiting tested
- [ ] Error handling tested

---

## Cost Estimates

### Monthly Costs (USD)

#### Minimum Setup (Development)
| Service | Provider | Cost |
|---------|----------|------|
| Server | Hetzner CX11 | $5 |
| SMS | SMS.RU (pay-as-go) | $5-20 |
| Email | SendGrid Free | $0 |
| Domain | Namecheap | $1 |
| **Total** | | **$11-26/month** |

#### Recommended Setup (Production)
| Service | Provider | Cost |
|---------|----------|------|
| Server | DigitalOcean Basic | $12 |
| Database | DigitalOcean Managed PostgreSQL | $15 |
| SMS | Twilio (pay-as-go) | $20-50 |
| Email | SendGrid Essentials | $15 |
| Storage | AWS S3 or DigitalOcean Spaces | $5 |
| Domain | Namecheap | $1 |
| CDN | Cloudflare Free | $0 |
| **Total** | | **$68-98/month** |

#### Enterprise Setup (High Scale)
| Service | Provider | Cost |
|---------|----------|------|
| Server | DigitalOcean 4GB | $24 |
| Database | DigitalOcean Managed PostgreSQL | $15 |
| Load Balancer | DigitalOcean | $12 |
| SMS | Twilio (volume) | $50-100 |
| Email | SendGrid Pro | $90 |
| Storage | AWS S3 | $10-30 |
| Domain | Namecheap | $1 |
| CDN | Cloudflare Pro | $20 |
| Monitoring | Datadog | $15 |
| **Total** | | **$237-307/month** |

### SMS Cost Breakdown
- **Development/Testing:** 100-500 SMS/month = $5-20
- **Small app (1000 users):** ~1000 SMS/month = $20-50
- **Medium app (10k users):** ~5000 SMS/month = $100-250
- **Large app (100k users):** ~20k SMS/month = $400-1000

**Cost Savings Tips:**
1. Use email verification instead of SMS where possible
2. Implement OTP rate limiting (max 3 per hour)
3. Use SMS only for critical flows (registration, 2FA)
4. Consider SMS.RU for CIS countries (much cheaper)
5. Negotiate volume discounts with providers

---

## Quick Start Commands Reference

### Server Management
```bash
# Connect to server
ssh glowly@YOUR_SERVER_IP

# Check server status
pm2 status

# View logs
pm2 logs glowly-api

# Restart application
pm2 restart glowly-api

# Update code
cd ~/glowly-backend
git pull origin main
npm install
pm2 restart glowly-api

# Check Nginx status
sudo systemctl status nginx

# Reload Nginx configuration
sudo nginx -t && sudo systemctl reload nginx

# Check disk space
df -h

# Check memory usage
free -h

# Check database connection
psql -U glowly_user -d glowly_db -h localhost
```

### Database Management
```bash
# Connect to database
psql -U glowly_user -d glowly_db -h localhost

# Backup database
pg_dump -U glowly_user glowly_db > backup_$(date +%Y%m%d).sql

# Restore database
psql -U glowly_user glowly_db < backup_20240115.sql

# View all tables
\dt

# Describe table structure
\d users

# Exit psql
\q
```

### Security
```bash
# Check firewall status
sudo ufw status

# Allow HTTP/HTTPS
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Allow SSH
sudo ufw allow 22/tcp

# Enable firewall
sudo ufw enable

# View failed login attempts
sudo grep "Failed password" /var/log/auth.log

# Update SSL certificate
sudo certbot renew
```

---

## Next Steps

1. **Immediately:**
   - [ ] Rent a server (recommended: Hetzner CX11 for $5/month)
   - [ ] Set up database
   - [ ] Create SMS service account (SMS.RU for CIS or Twilio for global)

2. **This Week:**
   - [ ] Implement authentication endpoints (register, login, OTP)
   - [ ] Set up JWT token system
   - [ ] Test with iOS app

3. **Next Week:**
   - [ ] Implement user profile endpoints
   - [ ] Implement product CRUD endpoints
   - [ ] Set up file upload for product images

4. **Next 2 Weeks:**
   - [ ] Implement social features (posts, comments, likes)
   - [ ] Set up proper error handling
   - [ ] Configure production domain and SSL

5. **Before Launch:**
   - [ ] Complete security audit
   - [ ] Set up monitoring and backups
   - [ ] Load testing
   - [ ] iOS app integration testing

---

## Support Resources

### Documentation
- Node.js: https://nodejs.org/docs
- Express: https://expressjs.com/
- PostgreSQL: https://www.postgresql.org/docs/
- JWT: https://jwt.io/introduction
- Nginx: https://nginx.org/en/docs/

### Community Help
- Stack Overflow: https://stackoverflow.com/
- Reddit: r/node, r/webdev
- DigitalOcean Community: https://www.digitalocean.com/community

### Server Provider Docs
- DigitalOcean: https://docs.digitalocean.com/
- Hetzner: https://docs.hetzner.com/
- Linode: https://www.linode.com/docs/

---

**Created:** 2024-01-15
**Last Updated:** 2024-01-15
**Maintainer:** Glowly Development Team

**Note:** Keep this document updated as you implement features. Other developers and AI assistants will use this as the source of truth for backend integration.
