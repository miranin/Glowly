# API Integration Testing Guide

## Prerequisites

### 1. Update Backend URL

Update the base URL in `NetworkConfiguration.swift` to point to your actual backend server:

```swift
static let development = NetworkConfiguration(
    baseURL: "http://YOUR_BACKEND_URL",  // e.g., "http://localhost:8080" or your server IP
    defaultHeaders: [
        "Content-Type": "application/json",
        "Accept": "application/json"
    ],
    enableLogging: true
)
```

**Important Notes:**
- If testing locally on simulator with localhost backend, use: `http://localhost:PORT`
- If testing on physical device with local backend, use: `http://YOUR_COMPUTER_IP:PORT`
- If using a deployed backend, use the full URL from your API docs

---

## Testing Methods

### Method 1: Test via iOS Simulator (Recommended)

#### Setup:
1. Make sure your backend server is running
2. Update the base URL in `NetworkConfiguration.swift` as shown above
3. Build and run the app in Xcode (⌘R)

#### Test Registration:

1. **Launch the app** in iOS Simulator
2. **Navigate to Registration screen**
3. **Fill in the form:**
   - Name: `Test User`
   - Email: `test@example.com`
   - Phone: `700 123 45 67`
   - Password: `SecurePass123!`
   - Confirm Password: `SecurePass123!`
4. **Tap "Зарегистрироваться"**

#### What to Check:

**In Xcode Console** (View → Debug Area → Activate Console):

You should see detailed logging like:
```
🌐 [NetworkService] Request:
  URL: http://YOUR_BACKEND_URL/api/auth/register
  Method: POST
  Headers: {
    "Content-Type": "application/json",
    "Accept": "application/json"
  }
  Body: {
    "username": "Test User",
    "email": "test@example.com",
    "phone_number": "+7700123 45 67",
    "password": "SecurePass123!",
    "valid": true
  }

📥 [NetworkService] Response:
  Status Code: 201
  Body: {
    "user": {...},
    "token": "...",
    "refreshToken": "..."
  }
```

**Success Indicators:**
- ✅ Status Code: 201 (User registered successfully)
- ✅ User is authenticated automatically
- ✅ Tokens are stored in Keychain
- ✅ No error bottom sheet appears

**Failure Indicators:**
- ❌ Status Code: 400 (Bad Request - check request format)
- ❌ Status Code: 500 (Server Error - check backend logs)
- ❌ Error message appears in bottom sheet
- ❌ Connection timeout

#### Test Login:

1. **Navigate to Login screen**
2. **Fill in credentials:**
   - Email: `test@example.com` (or the registered email)
   - Password: `SecurePass123!`
3. **Tap "Войти"**

**Expected Console Output:**
```
🌐 [NetworkService] Request:
  URL: http://YOUR_BACKEND_URL/api/auth/login
  Method: POST
  Body: {
    "email": "test@example.com",
    "password": "SecurePass123!"
  }

📥 [NetworkService] Response:
  Status Code: 200
  Body: {
    "user": {...},
    "token": "...",
    "refreshToken": "..."
  }
```

---

### Method 2: Unit Tests

Create a test file to verify the API integration programmatically:

**Location:** `GlowlyTests/AuthenticationAPITests.swift`

```swift
import XCTest
@testable import Glowly

final class AuthenticationAPITests: XCTestCase {
    var networkService: NetworkService!

    override func setUp() {
        super.setUp()
        // Use your actual backend URL here
        let config = NetworkConfiguration(
            baseURL: "http://YOUR_BACKEND_URL",
            defaultHeaders: [
                "Content-Type": "application/json",
                "Accept": "application/json"
            ],
            enableLogging: true
        )
        networkService = NetworkService(configuration: config)
    }

    func testRegistrationAPI() async throws {
        // Arrange
        let request = RegisterRequest(
            username: "TestUser_\(UUID().uuidString.prefix(8))",
            email: "test_\(UUID().uuidString.prefix(8))@example.com",
            phoneNumber: "+7700\(Int.random(in: 1000000...9999999))",
            password: "SecurePass123!",
            valid: true
        )

        // Act
        let endpoint = AuthEndpoints.register(request)
        let response: AuthResponse = try await networkService.request(endpoint)

        // Assert
        XCTAssertNotNil(response.token, "Access token should not be nil")
        XCTAssertNotNil(response.refreshToken, "Refresh token should not be nil")
        XCTAssertEqual(response.user.email, request.email, "Email should match")
        XCTAssertNotNil(response.user.id, "User ID should not be nil")

        print("✅ Registration API test passed!")
        print("User ID: \(response.user.id)")
        print("Token: \(response.token.prefix(20))...")
    }

    func testLoginAPI() async throws {
        // First register a user
        let email = "test_login_\(UUID().uuidString.prefix(8))@example.com"
        let password = "SecurePass123!"

        let registerRequest = RegisterRequest(
            username: "TestUser",
            email: email,
            phoneNumber: "+77001234567",
            password: password,
            valid: true
        )

        let registerEndpoint = AuthEndpoints.register(registerRequest)
        let _: AuthResponse = try await networkService.request(registerEndpoint)

        // Now test login
        let loginRequest = LoginRequest(usernameOrEmail: email, password: password)
        let loginEndpoint = AuthEndpoints.login(loginRequest)
        let loginResponse: AuthResponse = try await networkService.request(loginEndpoint)

        // Assert
        XCTAssertNotNil(loginResponse.token, "Login should return access token")
        XCTAssertEqual(loginResponse.user.email, email, "Email should match")

        print("✅ Login API test passed!")
    }
}
```

**Run Tests:**
```bash
# Command line
xcodebuild test -scheme Glowly -destination 'platform=iOS Simulator,name=iPhone 15'

# Or in Xcode: ⌘U
```

---

### Method 3: Network Debugging with Proxyman/Charles

1. **Install Proxyman** (https://proxyman.io) or Charles Proxy
2. **Configure iOS Simulator** to route traffic through proxy
3. **Run the app** and perform registration
4. **Inspect the requests** in Proxyman:
   - Request URL
   - Request headers
   - Request body (JSON)
   - Response status code
   - Response body
   - Response time

**Benefits:**
- See exact JSON being sent/received
- Debug SSL/TLS issues
- Mock responses for testing
- Test error scenarios

---

### Method 4: Backend Logs

Check your backend server logs to verify:

1. **Request received:**
   ```
   POST /api/auth/register
   Body: {
     "username": "Test User",
     "email": "test@example.com",
     ...
   }
   ```

2. **Database insertion:**
   ```
   User created with ID: xxx
   ```

3. **Response sent:**
   ```
   Status: 201
   Response: { "user": {...}, "token": "..." }
   ```

---

## Common Issues & Solutions

### Issue 1: Connection Refused / Timeout

**Symptoms:**
```
❌ Error: No internet connection
❌ Error: Request timed out
```

**Solutions:**
- ✅ Verify backend server is running
- ✅ Check firewall settings
- ✅ For localhost: Use `http://localhost:PORT` (simulator) or `http://YOUR_IP:PORT` (device)
- ✅ Ensure network configuration uses correct URL

### Issue 2: 400 Bad Request

**Symptoms:**
```
📥 Status Code: 400
❌ Error: Username is required
```

**Solutions:**
- ✅ Check request body matches backend schema exactly
- ✅ Verify field names (snake_case vs camelCase)
- ✅ Check backend expects `phone_number` not `phoneNumber`
- ✅ Verify `JSONEncoder.keyEncodingStrategy = .convertToSnakeCase` is set

### Issue 3: 401 Unauthorized

**Symptoms:**
```
📥 Status Code: 401
❌ Error: Invalid credentials
```

**Solutions:**
- ✅ User doesn't exist (registration failed)
- ✅ Wrong password
- ✅ Token expired (for protected endpoints)

### Issue 4: 500 Server Error

**Symptoms:**
```
📥 Status Code: 500
❌ Error: Server error. Please try again later.
```

**Solutions:**
- ✅ Check backend server logs for stack trace
- ✅ Verify database is connected
- ✅ Check backend can hash passwords
- ✅ Ensure backend can generate JWT tokens

### Issue 5: Decoding Failed

**Symptoms:**
```
❌ Error: Invalid response from server
DecodingError: keyNotFound(...)
```

**Solutions:**
- ✅ Backend response doesn't match `AuthResponse` model
- ✅ Check field names in response
- ✅ Verify date format is ISO8601
- ✅ Add debug print of raw response JSON

---

## Testing Checklist

### Registration Flow
- [ ] Fill registration form with valid data
- [ ] Submit registration
- [ ] Verify request is sent to `/api/auth/register`
- [ ] Check request body contains all required fields
- [ ] Verify 201 response received
- [ ] Confirm user object returned
- [ ] Verify JWT tokens received
- [ ] Check tokens stored in Keychain
- [ ] Confirm user is authenticated

### Login Flow
- [ ] Fill login form with registered credentials
- [ ] Submit login
- [ ] Verify request sent to `/api/auth/login`
- [ ] Check 200 response received
- [ ] Verify JWT tokens received
- [ ] Confirm user authenticated

### Error Handling
- [ ] Test with existing email (should show "Email already exists")
- [ ] Test with invalid email format (should show validation error)
- [ ] Test with weak password (should show "Weak password")
- [ ] Test with wrong credentials (should show "Invalid credentials")
- [ ] Test with server down (should show "No internet connection")

---

## Success Criteria

✅ **Integration is working if:**
1. Registration creates user in backend database
2. Login authenticates existing user
3. JWT tokens are returned and stored
4. User object matches expected schema
5. Error responses are handled gracefully
6. Network logs show correct request/response format

---

## Next Steps After Successful Testing

1. **Add Token Refresh Logic**
   - Implement automatic token refresh before expiry
   - Handle 401 responses by refreshing token

2. **Add Protected Endpoints**
   - Test endpoints that require authentication
   - Verify JWT token is sent in Authorization header

3. **Test on Physical Device**
   - Install on real iPhone/iPad
   - Test with actual backend server (not localhost)

4. **Performance Testing**
   - Test with slow network conditions
   - Verify timeout handling
   - Check retry logic

5. **Security Testing**
   - Verify HTTPS is used in production
   - Check certificate pinning (if required)
   - Test token storage security
