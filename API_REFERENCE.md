# API Reference - Glowly Backend

Complete API endpoint reference for the Glowly backend. This document serves as the contract between iOS frontend and backend API.

**Base URL (Development):** `http://172.234.116.129:8080`
**Base URL (Production):** `https://api.glowly.app`

**API Version:** v1
**All endpoints should be prefixed with:** `/api`

---

## Table of Contents
1. [Authentication](#authentication) - 9 endpoints
2. [User Management](#user-management) - 7 endpoints
3. [Products](#products) - 6 endpoints
4. [Social Feed](#social-feed) - 8 endpoints
5. [Comments](#comments) - 5 endpoints
6. [WishList](#wishlist) - 4 endpoints
7. [Social Interactions](#social-interactions) - 5 endpoints

**Total: ~44 endpoints**

---

## General Information

### Request Headers
```
Content-Type: application/json
Accept: application/json
```

### Authenticated Requests
```
Authorization: Bearer {access_token}
```

### Response Format
**Success (200-299):**
```json
{
  "data": { ... }
}
```

**Error (400-599):**
```json
{
  "statusCode": 400,
  "message": "Error description",
  "errors": [
    {
      "field": "email",
      "message": "Email already exists"
    }
  ],
  "timestamp": "2024-01-15T10:30:00Z"
}
```

### Pagination
All list endpoints support pagination:
```
GET /api/resource?page=1&limit=20&sort=-created_at
```

Response includes pagination metadata:
```json
{
  "data": [...],
  "pagination": {
    "currentPage": 1,
    "totalPages": 5,
    "totalCount": 100,
    "pageSize": 20
  }
}
```

---

## Authentication

### POST /api/auth/register
Create a new user account.

**Request Body:**
```json
{
  "username": "string (3-30 chars, alphanumeric)",
  "email": "string (valid email)",
  "phoneNumber": "string (E.164 format, e.g., +77001234567)",
  "password": "string (min 8 chars)"
}
```

**Response (201 Created):**
```json
{
  "accessToken": "eyJhbGc...",
  "refreshToken": "eyJhbGc...",
  "tokenType": "Bearer",
  "username": "testuser",
  "email": "test@example.com",
  "roles": ["USER"]
}
```

**Error Codes:**
- `400` - Validation error or user already exists
- `500` - Server error

---

### POST /api/auth/login
Authenticate existing user.

**Request Body:**
```json
{
  "usernameOrEmail": "string (email, username, or phone)",
  "password": "string"
}
```

**Response (200 OK):**
```json
{
  "accessToken": "eyJhbGc...",
  "refreshToken": "eyJhbGc...",
  "tokenType": "Bearer",
  "username": "testuser",
  "email": "test@example.com",
  "roles": ["USER", "PREMIUM_USER"]
}
```

**Error Codes:**
- `401` - Invalid credentials
- `404` - User not found
- `500` - Server error

---

### POST /api/auth/logout
Invalidate user session and tokens.

**Headers:** `Authorization: Bearer {token}`

**Request Body:** Empty

**Response (200 OK):**
```json
{
  "message": "Logged out successfully"
}
```

---

### POST /api/auth/refresh
Refresh expired access token.

**Request Body:**
```json
{
  "refreshToken": "string"
}
```

**Response (200 OK):**
```json
{
  "token": "new_access_token",
  "refreshToken": "new_refresh_token"
}
```

**Error Codes:**
- `401` - Invalid or expired refresh token

---

### POST /api/auth/verify-otp
Verify OTP code sent to email or phone.

**Request Body:**
```json
{
  "identifier": "string (email or phone)",
  "otpCode": "string (6 digits)"
}
```

**Response (200 OK):**
```json
{
  "message": "Verification successful",
  "verified": true,
  "identifier": "test@example.com"
}
```

**Error Codes:**
- `400` - Invalid or expired OTP

---

### POST /api/auth/resend-otp
Resend OTP code.

**Request Body:**
```json
{
  "identifier": "string (email or phone)"
}
```

**Response (200 OK):**
```json
{
  "message": "OTP sent successfully",
  "identifier": "test@example.com",
  "maskedIdentifier": "te**@example.com",
  "expiresIn": 600
}
```

**Error Codes:**
- `429` - Rate limit exceeded (max 3 per hour)

---

### POST /api/auth/forgot-password
Initiate password reset flow.

**Request Body:**
```json
{
  "email": "string"
}
```

**Response (200 OK):**
```json
{
  "message": "If the email exists, a password reset link has been sent"
}
```

Note: Always returns success for security (doesn't reveal if email exists)

---

### POST /api/auth/reset-password
Complete password reset with token.

**Request Body:**
```json
{
  "token": "string (from reset email)",
  "newPassword": "string (min 8 chars)"
}
```

**Response (200 OK):**
```json
{
  "message": "Password reset successful"
}
```

**Error Codes:**
- `400` - Invalid, expired, or already used token

---

### POST /api/auth/verify-email
Verify email address with token.

**Request Body:**
```json
{
  "token": "string (from verification email)"
}
```

**Response (200 OK):**
```json
{
  "message": "Email verified successfully"
}
```

---

## User Management

### GET /api/users/:userId
Get user profile.

**Headers:** `Authorization: Bearer {token}`

**Response (200 OK):**
```json
{
  "id": "uuid",
  "email": "test@example.com",
  "username": "testuser",
  "name": "Test User",
  "profilePhotoUrl": "https://...",
  "authProvider": "email",
  "isPremium": false,
  "createdAt": "2024-01-15T10:00:00Z",
  "lastLoginAt": "2024-01-15T10:30:00Z"
}
```

---

### PUT /api/users/:userId
Update user profile.

**Headers:** `Authorization: Bearer {token}`

**Request Body:**
```json
{
  "name": "string (optional)",
  "username": "string (optional)",
  "profilePhotoUrl": "string (optional)"
}
```

**Response (200 OK):**
```json
{
  "id": "uuid",
  "email": "test@example.com",
  "username": "newusername",
  "name": "New Name",
  "updatedAt": "2024-01-15T11:00:00Z"
}
```

---

### DELETE /api/users/:userId
Delete user account (soft delete).

**Headers:** `Authorization: Bearer {token}`

**Response (200 OK):**
```json
{
  "message": "Account deleted successfully"
}
```

---

### POST /api/users/:userId/profile
Create/update user onboarding profile.

**Headers:** `Authorization: Bearer {token}`

**Request Body:**
```json
{
  "hasCompletedOnboarding": true,
  "ageRange": "25-34",
  "sex": "female",
  "skinType": "combination",
  "skinTone": "medium",
  "skinConditions": ["acne", "darkSpots"],
  "allergies": ["fragrance"],
  "sensitivities": ["alcohol"],
  "experienceLevel": "intermediate",
  "beautyGoals": ["hydration", "antiAging"],
  "preferredBrands": ["Estée Lauder", "La Mer"],
  "makeupFrequency": "daily",
  "skincareRoutineComplexity": "moderate",
  "preferredProductTypes": ["serum", "moisturizer"]
}
```

**Response (201 Created):**
```json
{
  "id": "uuid",
  "userId": "uuid",
  "hasCompletedOnboarding": true,
  "skinType": "combination",
  "createdAt": "2024-01-15T10:00:00Z"
}
```

---

### GET /api/users/:userId/profile
Get user onboarding profile.

**Headers:** `Authorization: Bearer {token}`

**Response (200 OK):**
```json
{
  "id": "uuid",
  "userId": "uuid",
  "hasCompletedOnboarding": true,
  "ageRange": "25-34",
  "sex": "female",
  "skinType": "combination",
  "skinTone": "medium",
  "beautyGoals": ["hydration", "antiAging"],
  "lastUpdated": "2024-01-15T10:00:00Z"
}
```

---

### PATCH /api/users/:userId/premium
Upgrade user to premium.

**Headers:** `Authorization: Bearer {token}`

**Request Body:**
```json
{
  "subscriptionType": "monthly",
  "paymentProvider": "stripe",
  "paymentProviderSubscriptionId": "sub_123..."
}
```

**Response (200 OK):**
```json
{
  "id": "uuid",
  "userId": "uuid",
  "isPremium": true,
  "subscriptionType": "monthly",
  "expiresAt": "2024-02-15T10:00:00Z"
}
```

---

## Products

### POST /api/products
Create a new product.

**Headers:** `Authorization: Bearer {token}`

**Request Body:**
```json
{
  "name": "Hydrating Serum",
  "brand": "Estée Lauder",
  "category": "serum",
  "applicationZone": "face",
  "purchaseDate": "2024-01-15",
  "expirationDate": "2025-01-15",
  "barcode": "123456789",
  "imageUrl": "https://...",
  "notes": "Use morning and evening",
  "ingredients": "Water, Hyaluronic Acid...",
  "howToUse": "Apply 2-3 drops to clean skin",
  "benefits": ["hydration", "plumping"],
  "warnings": ["Avoid eye area"],
  "isSensitiveSafe": true,
  "isAcneSafe": true
}
```

**Response (201 Created):**
```json
{
  "id": "uuid",
  "userId": "uuid",
  "name": "Hydrating Serum",
  "brand": "Estée Lauder",
  "category": "serum",
  "createdAt": "2024-01-15T10:00:00Z"
}
```

---

### GET /api/products
List user's products (paginated).

**Headers:** `Authorization: Bearer {token}`

**Query Parameters:**
- `page` (default: 1)
- `limit` (default: 20, max: 100)
- `category` (optional filter)
- `applicationZone` (optional filter)
- `isActive` (optional filter, default: true)
- `sort` (default: -created_at)

**Response (200 OK):**
```json
{
  "data": [
    {
      "id": "uuid",
      "name": "Hydrating Serum",
      "brand": "Estée Lauder",
      "category": "serum",
      "imageUrl": "https://...",
      "purchaseDate": "2024-01-15",
      "isActive": true
    }
  ],
  "pagination": {
    "currentPage": 1,
    "totalPages": 3,
    "totalCount": 45,
    "pageSize": 20
  }
}
```

---

### GET /api/products/:productId
Get product details.

**Headers:** `Authorization: Bearer {token}`

**Response (200 OK):**
```json
{
  "id": "uuid",
  "userId": "uuid",
  "name": "Hydrating Serum",
  "brand": "Estée Lauder",
  "category": "serum",
  "applicationZone": "face",
  "purchaseDate": "2024-01-15",
  "expirationDate": "2025-01-15",
  "ingredients": "Water, Hyaluronic Acid...",
  "howToUse": "Apply 2-3 drops",
  "benefits": ["hydration", "plumping"],
  "warnings": ["Avoid eye area"],
  "isSensitiveSafe": true,
  "isAcneSafe": true,
  "createdAt": "2024-01-15T10:00:00Z"
}
```

---

### PUT /api/products/:productId
Update product.

**Headers:** `Authorization: Bearer {token}`

**Request Body:** Same as POST, all fields optional

**Response (200 OK):**
```json
{
  "id": "uuid",
  "name": "Updated Name",
  "updatedAt": "2024-01-15T11:00:00Z"
}
```

---

### DELETE /api/products/:productId
Delete product (soft delete).

**Headers:** `Authorization: Bearer {token}`

**Response (200 OK):**
```json
{
  "message": "Product deleted successfully"
}
```

---

### POST /api/products/:productId/upload-image
Upload product image.

**Headers:**
- `Authorization: Bearer {token}`
- `Content-Type: multipart/form-data`

**Request Body (multipart/form-data):**
```
image: File (JPG, PNG, max 10MB)
```

**Response (200 OK):**
```json
{
  "id": "uuid",
  "url": "https://cdn.glowly.app/products/abc123.jpg",
  "uploadedAt": "2024-01-15T10:00:00Z",
  "size": 2048576
}
```

---

## Social Feed

### POST /api/posts
Create a new post (premium feature).

**Headers:** `Authorization: Bearer {token}`

**Request Body:**
```json
{
  "content": "Just tried this amazing serum! #glowingskin",
  "isPremiumContent": false,
  "isPublic": true
}
```

**Response (201 Created):**
```json
{
  "id": "uuid",
  "userId": "uuid",
  "content": "Just tried this amazing serum!",
  "likesCount": 0,
  "commentsCount": 0,
  "createdAt": "2024-01-15T10:00:00Z"
}
```

**Error Codes:**
- `403` - Premium subscription required

---

### GET /api/posts
Get feed (paginated).

**Headers:** `Authorization: Bearer {token}`

**Query Parameters:**
- `page` (default: 1)
- `limit` (default: 20)
- `userId` (optional, filter by user)

**Response (200 OK):**
```json
{
  "data": [
    {
      "id": "uuid",
      "userId": "uuid",
      "userName": "testuser",
      "userAvatar": "https://...",
      "content": "Amazing product!",
      "media": [
        {
          "id": "uuid",
          "type": "image",
          "url": "https://...",
          "thumbnailUrl": "https://..."
        }
      ],
      "likesCount": 42,
      "commentsCount": 5,
      "isLiked": true,
      "isPremium": false,
      "createdAt": "2024-01-15T10:00:00Z"
    }
  ],
  "pagination": { ... }
}
```

---

### GET /api/posts/:postId
Get post details.

**Headers:** `Authorization: Bearer {token}`

**Response (200 OK):**
```json
{
  "id": "uuid",
  "userId": "uuid",
  "userName": "testuser",
  "userAvatar": "https://...",
  "content": "Amazing product!",
  "media": [...],
  "likesCount": 42,
  "commentsCount": 5,
  "isLiked": true,
  "createdAt": "2024-01-15T10:00:00Z"
}
```

---

### PUT /api/posts/:postId
Update post (owner only).

**Headers:** `Authorization: Bearer {token}`

**Request Body:**
```json
{
  "content": "Updated content"
}
```

**Response (200 OK):**
```json
{
  "id": "uuid",
  "content": "Updated content",
  "updatedAt": "2024-01-15T11:00:00Z"
}
```

---

### DELETE /api/posts/:postId
Delete post (owner only).

**Headers:** `Authorization: Bearer {token}`

**Response (200 OK):**
```json
{
  "message": "Post deleted successfully"
}
```

---

### POST /api/posts/:postId/like
Like a post.

**Headers:** `Authorization: Bearer {token}`

**Response (200 OK):**
```json
{
  "message": "Post liked",
  "likesCount": 43
}
```

---

### DELETE /api/posts/:postId/like
Unlike a post.

**Headers:** `Authorization: Bearer {token}`

**Response (200 OK):**
```json
{
  "message": "Post unliked",
  "likesCount": 42
}
```

---

### POST /api/posts/:postId/media
Upload media for post.

**Headers:**
- `Authorization: Bearer {token}`
- `Content-Type: multipart/form-data`

**Request Body (multipart/form-data):**
```
files: File[] (multiple images/videos, max 10MB each)
```

**Response (200 OK):**
```json
{
  "media": [
    {
      "id": "uuid",
      "type": "image",
      "url": "https://...",
      "thumbnailUrl": "https://...",
      "displayOrder": 0
    }
  ]
}
```

---

## Comments

### POST /api/posts/:postId/comments
Create a comment.

**Headers:** `Authorization: Bearer {token}`

**Request Body:**
```json
{
  "content": "Great post!",
  "parentCommentId": "uuid (optional, for replies)"
}
```

**Response (201 Created):**
```json
{
  "id": "uuid",
  "postId": "uuid",
  "userId": "uuid",
  "userName": "testuser",
  "userAvatar": "https://...",
  "content": "Great post!",
  "likesCount": 0,
  "createdAt": "2024-01-15T10:00:00Z"
}
```

---

### GET /api/posts/:postId/comments
Get post comments (paginated).

**Headers:** `Authorization: Bearer {token}`

**Query Parameters:**
- `page` (default: 1)
- `limit` (default: 20)

**Response (200 OK):**
```json
{
  "data": [
    {
      "id": "uuid",
      "postId": "uuid",
      "userId": "uuid",
      "userName": "testuser",
      "userAvatar": "https://...",
      "content": "Great post!",
      "likesCount": 5,
      "isLiked": false,
      "createdAt": "2024-01-15T10:00:00Z"
    }
  ],
  "pagination": { ... }
}
```

---

### PUT /api/comments/:commentId
Update comment (owner only).

**Headers:** `Authorization: Bearer {token}`

**Request Body:**
```json
{
  "content": "Updated comment"
}
```

**Response (200 OK):**
```json
{
  "id": "uuid",
  "content": "Updated comment",
  "updatedAt": "2024-01-15T11:00:00Z"
}
```

---

### DELETE /api/comments/:commentId
Delete comment (owner only).

**Headers:** `Authorization: Bearer {token}`

**Response (200 OK):**
```json
{
  "message": "Comment deleted successfully"
}
```

---

### POST /api/comments/:commentId/like
Like a comment.

**Headers:** `Authorization: Bearer {token}`

**Response (200 OK):**
```json
{
  "message": "Comment liked",
  "likesCount": 6
}
```

---

## WishList

### POST /api/wishlist
Add item to wishlist.

**Headers:** `Authorization: Bearer {token}`

**Request Body:**
```json
{
  "productId": "uuid (optional, if from products table)",
  "productName": "Hydrating Serum",
  "productBrand": "Estée Lauder",
  "category": "serum",
  "imageUrl": "https://...",
  "externalUrl": "https://store.com/product",
  "fromUserId": "uuid (optional, if shared by another user)",
  "fromPostId": "uuid (optional, if from a post)",
  "priority": 1,
  "notes": "Want to try this!"
}
```

**Response (201 Created):**
```json
{
  "id": "uuid",
  "userId": "uuid",
  "productName": "Hydrating Serum",
  "addedAt": "2024-01-15T10:00:00Z"
}
```

---

### GET /api/wishlist
Get user's wishlist (paginated).

**Headers:** `Authorization: Bearer {token}`

**Query Parameters:**
- `page` (default: 1)
- `limit` (default: 20)
- `category` (optional filter)

**Response (200 OK):**
```json
{
  "data": [
    {
      "id": "uuid",
      "productName": "Hydrating Serum",
      "productBrand": "Estée Lauder",
      "category": "serum",
      "imageUrl": "https://...",
      "fromUserName": "friend123",
      "priority": 1,
      "addedAt": "2024-01-15T10:00:00Z"
    }
  ],
  "pagination": { ... }
}
```

---

### DELETE /api/wishlist/:itemId
Remove item from wishlist.

**Headers:** `Authorization: Bearer {token}`

**Response (200 OK):**
```json
{
  "message": "Item removed from wishlist"
}
```

---

### PUT /api/wishlist/:itemId
Update wishlist item.

**Headers:** `Authorization: Bearer {token}`

**Request Body:**
```json
{
  "priority": 2,
  "notes": "Updated notes"
}
```

**Response (200 OK):**
```json
{
  "id": "uuid",
  "priority": 2,
  "notes": "Updated notes"
}
```

---

## Social Interactions

### GET /api/users/:userId/profile/social
Get user's social profile.

**Headers:** `Authorization: Bearer {token}`

**Response (200 OK):**
```json
{
  "id": "uuid",
  "userId": "uuid",
  "userName": "testuser",
  "bio": "Beauty enthusiast",
  "avatar": "https://...",
  "isPremium": false,
  "userType": "regular",
  "followersCount": 150,
  "followingCount": 200,
  "postsCount": 42,
  "isFollowing": true,
  "cosmeticBagPreview": [
    {
      "id": "uuid",
      "name": "Product Name",
      "imageUrl": "https://..."
    }
  ],
  "createdAt": "2024-01-01T00:00:00Z"
}
```

---

### GET /api/users/:userId/following
Get users that this user is following.

**Headers:** `Authorization: Bearer {token}`

**Query Parameters:**
- `page` (default: 1)
- `limit` (default: 20)

**Response (200 OK):**
```json
{
  "data": [
    {
      "id": "uuid",
      "userName": "friend123",
      "avatar": "https://...",
      "isPremium": false,
      "followersCount": 100
    }
  ],
  "pagination": { ... }
}
```

---

### GET /api/users/:userId/followers
Get users following this user.

**Headers:** `Authorization: Bearer {token}`

**Query Parameters:**
- `page` (default: 1)
- `limit` (default: 20)

**Response (200 OK):**
```json
{
  "data": [
    {
      "id": "uuid",
      "userName": "follower456",
      "avatar": "https://...",
      "isPremium": true,
      "followersCount": 50
    }
  ],
  "pagination": { ... }
}
```

---

### POST /api/users/:userId/follow
Follow a user.

**Headers:** `Authorization: Bearer {token}`

**Response (200 OK):**
```json
{
  "message": "User followed successfully",
  "followersCount": 151
}
```

---

### DELETE /api/users/:userId/follow
Unfollow a user.

**Headers:** `Authorization: Bearer {token}`

**Response (200 OK):**
```json
{
  "message": "User unfollowed successfully",
  "followersCount": 150
}
```

---

## HTTP Status Codes

- `200 OK` - Request successful
- `201 Created` - Resource created
- `400 Bad Request` - Invalid request data
- `401 Unauthorized` - Authentication required or invalid token
- `403 Forbidden` - Insufficient permissions
- `404 Not Found` - Resource not found
- `409 Conflict` - Resource conflict (e.g., duplicate email)
- `429 Too Many Requests` - Rate limit exceeded
- `500 Internal Server Error` - Server error

---

## Rate Limiting

### Global Rate Limits
- **API calls:** 100 requests per 15 minutes per IP
- **Authentication:** 5 attempts per 15 minutes per IP
- **OTP requests:** 3 requests per hour per identifier

### Response Headers
```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1705320000
```

---

## Testing Endpoints

### Health Check
```
GET /api/health

Response:
{
  "status": "ok",
  "timestamp": "2024-01-15T10:30:00Z",
  "version": "1.0.0"
}
```

### API Version
```
GET /api/version

Response:
{
  "version": "1.0.0",
  "buildDate": "2024-01-15"
}
```

---

**Created:** 2024-01-15
**Last Updated:** 2024-01-15
**API Version:** 1.0
**Maintainer:** Glowly Development Team

**Note:** This is a living document. Update as new endpoints are added or existing ones change.
