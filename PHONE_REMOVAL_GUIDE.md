# Phone Number Removal Guide

This document tracks the removal of phone number authentication from the Glowly app, switching to email-only with OTP verification.

## Changes Completed ✅

### 1. API Models
- [x] **RegisterRequest.swift** - Removed `phoneNumber` field, now email-only
- [x] **LoginRequest.swift** - Already generic (`usernameOrEmail`), no changes needed

### 2. Registration Flow
- [x] **RegistrationViewModel.swift** - Removed:
  - `@Published var phone` property
  - `RegistrationType` enum (email/phone)
  - `signUpWithPhone()` method
  - `isValidPhone()` validation
  - `formatPhone()` and `handlePhoneInput()` methods
  - `phoneBorderColor()` method
  - `handleRegistrationTypeChange()` method

- [x] **RegistrationView.swift** - Removed:
  - `Field.phone` enum case
  - Segmented control for email/phone selection
  - `phoneInputField` view
  - Phone-related navigation logic in OTP

## Changes Needed ⚠️

### 3. Login Flow (IN PROGRESS)

**File:** `Glowly/Modules/Authentication/Login/ViewModel/LoginViewModel.swift`

Remove:
```swift
// Line 16: Remove phone property
@Published var phone: String = ""

// Lines 32-42: Remove LoginType enum completely
enum LoginType {
    case email
    case phone
    var placeholder: String { ... }
}

// Line 18: Remove loginType property
@Published var loginType: LoginType = .email

// Lines 95-127: Remove signInWithPhone() method completely

// Lines 240-243: Remove isValidPhone() method

// Lines 261-275: Remove formatPhone() method

// Lines 277-282: Remove handlePhoneInput() method

// Lines 228-238: Remove phoneBorderColor() method

// Lines 244-258: Remove handleLoginTypeChange() method
```

Keep and simplify:
```swift
// Lines 57-93: Keep signInWithEmail(), rename to private func signIn() async
// Lines 192-206: Keep isFormValid(), simplify to check email only:
func isFormValid() -> Bool {
    return isValidEmail(email) && !password.isEmpty
}

// Lines 208-212: Keep isValidEmail()
// Lines 220-226: Keep emailBorderColor()
```

**File:** `Glowly/Modules/Authentication/Login/View/LoginView.swift`

Remove:
```swift
// Remove Field.phone from enum (around line 16)
case name, email, phone, password -> case name, email, password

// Remove segmented control (around lines 130-142)
private var segmentedControl: some View { ... }

// Remove phoneInputField view (around lines 185-220)
private var phoneInputField: some View { ... }

// Update formSection to remove phone conditional (around lines 145-156):
VStack(spacing: 16) {
    emailInputField  // Remove: if viewModel.loginType == .email check
    passwordInputField
}

// Update OTP navigation (around lines 68-77):
contactInfo: viewModel.email  // Remove: conditional with phone
verificationType: .email  // Remove: conditional with .sms
```

### 4. AuthManager

**File:** `Glowly/Modules/Authentication/Shared/Services/AuthManager.swift`

Update:
```swift
// Lines 86-123: signIn() method
// Remove phone detection logic (line 96):
if identifier.hasPrefix("+7") {
    // Skip email validation for phone numbers
} else {
    // Validate email
}

// Simplify to always validate email:
guard isValidEmail(identifier) else {
    throw AuthError.invalidEmail
}

// Lines 127-168: signUp() method
// Remove phone detection (line 137)
// Always validate email format
```

### 5. OTP Verification

**File:** `Glowly/Modules/Authentication/Shared/Views/OTPVerificationView.swift`

Update:
```swift
// Already supports email/sms via enum
// Just ensure all callers use .email type
// Views using OTPVerificationView should pass:
// - contactInfo: email (not phone)
// - verificationType: .email (not .sms)
```

### 6. Debug/Test Views

**File:** `Glowly/Views/Debug/APITestView.swift`

Remove:
```swift
// Line 172: Remove phone number generation
let randomPhone = "+7700\(Int.random(in: 1000000...9999999))"

// Line 184: Remove phoneNumber from RegisterRequest
let request = RegisterRequest(
    username: testUsername,
    email: testEmail,
    password: "Test123!",
    valid: true
)  // phoneNumber removed
```

## Backend Documentation Updates Needed 📝

### 7. API_REFERENCE.md

Update:
```markdown
### POST /api/auth/register
Request Body:
{
  "username": "string",
  "email": "string",
  "password": "string"
  // phoneNumber REMOVED
}

### POST /api/auth/login
Request Body:
{
  "usernameOrEmail": "string (email or username only, phone removed)",
  "password": "string"
}

### POST /api/auth/verify-otp
Request Body:
{
  "identifier": "string (email only, phone support removed)",
  "otpCode": "string (6 digits)"
}

### POST /api/auth/resend-otp
Request Body:
{
  "identifier": "string (email only, phone support removed)"
}
```

### 8. AUTH_IMPLEMENTATION.md

Update:
```javascript
// Remove phone number from register controller
exports.register = async (req, res) => {
  const { email, username, password } = req.body;
  // phoneNumber removed

  // Remove phone check in existingUser query
  const existingUser = await db.query(
    'SELECT id FROM users WHERE email = $1 OR username = $2',
    [email, username]  // phone_number removed
  );

  // Create user without phone
  const result = await db.query(
    `INSERT INTO users (email, username, password_hash, auth_provider)
     VALUES ($1, $2, $3, $4)
     RETURNING id, email, username, created_at`,
    [email, username, passwordHash, 'email']
  );
};

// Update login controller to not accept phone
exports.login = async (req, res) => {
  const { usernameOrEmail, password } = req.body;

  // Find user by email or username only (remove phone_number)
  const result = await db.query(
    `SELECT id, email, username, password_hash, is_premium
     FROM users
     WHERE (email = $1 OR username = $1) AND deleted_at IS NULL`,
    [usernameOrEmail]
  );
};

// Update OTP services to email-only
exports.verifyOtp = async (req, res) => {
  const { identifier, otpCode } = req.body;

  // identifier is always email now
  await db.query(
    'UPDATE users SET is_email_verified = TRUE WHERE email = $1',
    [identifier]
  );
};

exports.resendOtp = async (req, res) => {
  const { identifier } = req.body;

  // Always send via email, never SMS
  await emailService.sendOTP(identifier, otpCode);
};
```

### 9. DATABASE_SCHEMA.md

Update:
```sql
-- Make phone_number optional and not unique
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    username VARCHAR(30) UNIQUE,
    phone_number VARCHAR(20),  -- Made optional, removed UNIQUE
    password_hash VARCHAR(255) NOT NULL,
    -- ... rest of fields
    is_email_verified BOOLEAN DEFAULT FALSE,
    is_phone_verified BOOLEAN DEFAULT FALSE,  -- Keep for future use
);

-- Remove phone_number index since it's no longer used for auth
-- CREATE INDEX idx_users_phone ON users(phone_number); -- REMOVED

-- Update comments to indicate email-only auth
-- Phone number field kept for optional future features (profile data)
-- but NOT used for authentication
```

### 10. BACKEND_INTEGRATION_PLAN.md

Update:
```markdown
## SMS Service Integration

~~**Status:** Required for OTP verification~~
**Status:** NOT NEEDED - Using email-only OTP

~~You need to set up an SMS provider...~~

**Email Service (Required):**
- SendGrid (Free tier: 100 emails/day) - REQUIRED
- Mailgun (5,000 emails/month free)
- AWS SES ($0.10 per 1,000 emails)

**OTP Delivery:**
- ✅ Email OTP - Primary method (via SendGrid)
- ❌ SMS OTP - Removed, not implemented

**Cost Savings:**
- No SMS service needed - saves $5-50/month
- Email OTP is free (SendGrid free tier)
- Total monthly cost reduced by ~$20-50
```

### 11. CLAUDE.md

Update Known Technical Debt section:
```markdown
## Known Technical Debt

1. **Data Persistence:** ProductStore uses UserDefaults...
2. **API Security:** Hardcoded API keys...
3. **Mock Data:** FeedService, CommentService...
4. **Error Handling:** Limited error handling...
5. **Testing:** Minimal test coverage...
6. **Offline Sync:** No offline-first capability...

**Backend Integration Status:**
- ❌ Server not set up
- ❌ Database not configured
- ❌ API endpoints not implemented
- ✅ SMS service NOT NEEDED - Using email-only OTP (cost savings!)
- ✅ Email service required - SendGrid free tier recommended
- ✅ iOS network layer: 100% ready for email-only backend
```

## Implementation Checklist

### iOS App Changes
- [x] Remove phone from RegisterRequest model
- [x] Remove phone from RegistrationViewModel
- [x] Remove phone input from RegistrationView
- [ ] Remove phone from LoginViewModel (IN PROGRESS)
- [ ] Remove phone input from LoginView
- [ ] Update AuthManager to remove phone logic
- [ ] Update OTP views to email-only
- [ ] Remove phone from APITestView

### Backend Documentation
- [ ] Update API_REFERENCE.md endpoints
- [ ] Update AUTH_IMPLEMENTATION.md code examples
- [ ] Update DATABASE_SCHEMA.md to make phone optional
- [ ] Update BACKEND_INTEGRATION_PLAN.md to remove SMS requirements
- [ ] Update CLAUDE.md to reflect email-only auth

### Testing
- [ ] Test registration flow with email + OTP
- [ ] Test login flow with email/username
- [ ] Test OTP verification via email
- [ ] Test OTP resend via email
- [ ] Test forgot password flow
- [ ] Verify no phone number references remain

## Benefits of This Change

1. **Cost Savings:** $5-50/month (no SMS service needed)
2. **Simpler Backend:** No SMS provider integration
3. **Better UX:** One consistent auth method (email)
4. **Easier Testing:** Email OTP easier to test than SMS
5. **Less Code:** Removed ~500+ lines of phone-related code

## Migration Notes

- Phone number field kept in database schema (nullable) for future features
- Existing users with phone numbers will not be affected
- Phone number can be added to user profile later (non-auth feature)
- OTP system remains, just delivers via email instead of SMS

---

**Status:** 40% Complete (Registration done, Login in progress)
**Last Updated:** 2024-01-15
