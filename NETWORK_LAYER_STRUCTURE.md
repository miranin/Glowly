# Network Layer Structure

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    Presentation Layer                        │
│  (ViewModels, Views - LoginViewModel, RegistrationViewModel) │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│                    Service Layer                             │
│              (AuthManager, NetworkService)                   │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│                    Routing Layer                             │
│                 (AuthEndpoints enum)                         │
│  • Defines API paths                                         │
│  • Defines HTTP methods                                      │
│  • Associates requests with endpoints                        │
└──────────────────────┬──────────────────────────────────────┘
                       │
        ┌──────────────┴──────────────┐
        │                             │
        ▼                             ▼
┌──────────────────┐          ┌──────────────────┐
│  Request Models  │          │ Response Models  │
│  (DTOs to API)   │          │ (DTOs from API)  │
├──────────────────┤          ├──────────────────┤
│ • LoginRequest   │          │ • AuthResponse   │
│ • RegisterRequest│          │ • UserResponse   │
│ • VerifyOtp...   │          │ • VerifyOtp...   │
│ • ResendOtp...   │          │ • ResendOtp...   │
└──────────────────┘          └──────────────────┘
        │                             │
        └──────────────┬──────────────┘
                       │
                       ▼
              ┌────────────────┐
              │  NetworkService │
              │  (HTTP Client)  │
              └────────────────┘
                       │
                       ▼
              ┌────────────────┐
              │   Backend API   │
              └────────────────┘
```

## Directory Structure

```
Glowly/
└── Core/
    └── Network/
        ├── Endpoints/
        │   └── AuthEndpoints.swift           # Routing configuration
        │
        ├── Models/
        │   ├── Auth/
        │   │   ├── Requests/                 # Request DTOs
        │   │   │   ├── LoginRequest.swift
        │   │   │   ├── RegisterRequest.swift
        │   │   │   ├── VerifyOtpRequest.swift
        │   │   │   ├── ResendOtpRequest.swift
        │   │   │   ├── RefreshTokenRequest.swift
        │   │   │   ├── ForgotPasswordRequest.swift
        │   │   │   ├── ResetPasswordRequest.swift
        │   │   │   └── VerifyEmailRequest.swift
        │   │   │
        │   │   └── Responses/                # Response DTOs
        │   │       ├── AuthResponse.swift
        │   │       ├── UserResponse.swift
        │   │       ├── VerifyOtpResponse.swift
        │   │       ├── ResendOtpResponse.swift
        │   │       ├── RefreshTokenResponse.swift
        │   │       └── MessageResponse.swift
        │   │
        │   ├── HTTPMethod.swift              # HTTP method enum
        │   ├── NetworkError.swift            # Error types
        │   ├── NetworkConfiguration.swift    # Environment config
        │   └── NetworkDebugger.swift         # Debug utilities
        │
        ├── Protocols/
        │   └── APIEndpoint.swift             # Endpoint protocol
        │
        └── Services/
            ├── NetworkService.swift          # HTTP client
            └── NetworkReachability.swift     # Connection status
```

## Data Flow Example: User Login

```
1. User taps "Login" button
   └─> LoginView

2. View calls ViewModel
   └─> LoginViewModel.signInWithEmail()

3. ViewModel creates request
   └─> LoginRequest(usernameOrEmail: "user@example.com", password: "***")

4. ViewModel calls AuthManager
   └─> AuthManager.signIn(request)

5. AuthManager creates endpoint
   └─> AuthEndpoints.login(request)

6. AuthManager calls NetworkService
   └─> NetworkService.request<AuthResponse>(endpoint)

7. NetworkService builds URLRequest
   ├─> URL: "http://172.234.116.129:8080/api/auth/login"
   ├─> Method: POST
   └─> Body: {"usernameOrEmail":"user@example.com","password":"***"}

8. NetworkService makes HTTP request
   └─> URLSession.data(for: request)

9. Backend responds
   └─> {"accessToken":"...", "tokenType":"Bearer", "username":"...", ...}

10. NetworkService decodes response
    └─> AuthResponse instance

11. AuthManager converts to User model
    └─> response.toUser()

12. AuthManager stores token
    └─> KeychainService.save(token)

13. AuthManager updates state
    └─> @Published currentUser = user

14. View updates
    └─> Navigate to main app
```

## Key Principles

### 1. Separation of Concerns
- **Endpoints**: Routing logic only
- **Requests**: Outgoing data structure
- **Responses**: Incoming data structure
- **Service**: HTTP communication
- **Manager**: Business logic

### 2. Single Responsibility
Each file has ONE job:
- `LoginRequest.swift`: Define login request structure
- `AuthResponse.swift`: Define auth response structure
- `AuthEndpoints.swift`: Define routing for auth endpoints
- `NetworkService.swift`: Handle HTTP requests
- `AuthManager.swift`: Manage authentication state

### 3. Protocol-Oriented Design
```swift
protocol APIEndpoint {
    var path: String { get }
    var method: HTTPMethod { get }
    var body: Encodable? { get }
    // ...
}
```

### 4. Type Safety
```swift
// Compile-time safety
let endpoint = AuthEndpoints.login(request)  // ✅ Type-safe
let response: AuthResponse = try await network.request(endpoint)  // ✅ Type-safe

// Runtime errors avoided
let endpoint = AuthEndpoints.login("email", "password")  // ❌ Won't compile
```

### 5. Testability
```swift
// Easy to mock
class MockNetworkService: NetworkServiceProtocol {
    func request<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T {
        // Return mock data
    }
}

// Easy to test
func testLogin() async throws {
    let mockNetwork = MockNetworkService()
    let authManager = AuthManager(networkService: mockNetwork)
    let user = try await authManager.signIn(loginRequest)
    XCTAssertEqual(user.email, "test@example.com")
}
```

## Naming Conventions

### Requests
- **Pattern**: `{Action}Request.swift`
- **Examples**:
  - `LoginRequest.swift`
  - `RegisterRequest.swift`
  - `VerifyOtpRequest.swift`

### Responses
- **Pattern**: `{Data}Response.swift`
- **Examples**:
  - `AuthResponse.swift` (auth data)
  - `UserResponse.swift` (user data)
  - `MessageResponse.swift` (simple message)

### Properties
- **Format**: camelCase
- **Examples**: `usernameOrEmail`, `accessToken`, `phoneNumber`

## Adding New Endpoints

### Example: Add "Change Password" endpoint

#### 1. Create Request Model
```swift
// Core/Network/Models/Auth/Requests/ChangePasswordRequest.swift
struct ChangePasswordRequest: Encodable {
    let currentPassword: String
    let newPassword: String
}
```

#### 2. Create Response Model (if needed)
```swift
// Core/Network/Models/Auth/Responses/ChangePasswordResponse.swift
struct ChangePasswordResponse: Decodable {
    let message: String
    let success: Bool
}
```

#### 3. Add to AuthEndpoints
```swift
// Core/Network/Endpoints/AuthEndpoints.swift
enum AuthEndpoints: APIEndpoint {
    // ... existing cases ...
    case changePassword(ChangePasswordRequest)

    var path: String {
        switch self {
        // ... existing cases ...
        case .changePassword:
            return "/api/auth/change-password"
        }
    }

    var method: HTTPMethod {
        switch self {
        // ... existing cases ...
        case .changePassword:
            return .post
        }
    }

    var body: Encodable? {
        switch self {
        // ... existing cases ...
        case .changePassword(let request):
            return request
        }
    }
}
```

#### 4. Use in AuthManager
```swift
// Modules/Authentication/Shared/Services/AuthManager.swift
func changePassword(_ request: ChangePasswordRequest) async throws {
    let endpoint = AuthEndpoints.changePassword(request)
    let response: ChangePasswordResponse = try await networkService.request(endpoint)
    // Handle response
}
```

That's it! Clean, organized, and scalable.

## Benefits Checklist

✅ **Maintainability**: Easy to find and modify specific models
✅ **Scalability**: Simple to add new endpoints without cluttering
✅ **Readability**: Small, focused files with clear purposes
✅ **Testability**: Each component can be tested independently
✅ **Type Safety**: Compile-time checks prevent errors
✅ **Reusability**: Models can be reused across features
✅ **Team Collaboration**: Multiple developers can work without conflicts
✅ **Documentation**: Self-documenting through clear structure

## Next: Payment Endpoints

When adding payment features, follow the same pattern:

```
Core/Network/
├── Endpoints/
│   ├── AuthEndpoints.swift
│   └── PaymentEndpoints.swift       # New!
└── Models/
    ├── Auth/
    │   ├── Requests/
    │   └── Responses/
    └── Payment/                      # New!
        ├── Requests/
        │   ├── CreateSubscriptionRequest.swift
        │   └── CancelSubscriptionRequest.swift
        └── Responses/
            ├── SubscriptionResponse.swift
            └── PaymentStatusResponse.swift
```

Clean, consistent, scalable! 🚀
