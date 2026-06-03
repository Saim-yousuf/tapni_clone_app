# Admin Dashboard API Integration

This document is for the admin dashboard frontend integration.

## Base URLs

Local API:

```text
http://localhost:5000
```

Swagger docs:

```text
http://localhost:5000/api-docs
```

## Common Rules

All API responses include `success`.

Success:

```json
{
  "success": true,
  "message": "Request completed successfully"
}
```

Error:

```json
{
  "success": false,
  "message": "Error message"
}
```

Protected APIs require JWT token in headers:

```text
Authorization: Bearer YOUR_TOKEN_HERE
```

Use JSON request body:

```text
Content-Type: application/json
```

## Admin Auth

### Register Admin

```text
POST /api/admin/auth/register
```

Request:

```json
{
  "name": "Admin Name",
  "email": "admin@example.com",
  "password": "123456"
}
```

Success response:

```json
{
  "success": true,
  "message": "Admin registered successfully",
  "admin": {
    "id": "admin_id",
    "name": "Admin Name",
    "email": "admin@example.com"
  },
  "token": "jwt_token_here"
}
```

Possible errors:

```json
{
  "success": false,
  "message": "Admin already exists"
}
```

### Login Admin

```text
POST /api/admin/auth/login
```

Request:

```json
{
  "email": "admin@example.com",
  "password": "123456"
}
```

Success response:

```json
{
  "success": true,
  "message": "Admin logged in successfully",
  "admin": {
    "id": "admin_id",
    "name": "Admin Name",
    "email": "admin@example.com"
  },
  "token": "jwt_token_here"
}
```

Possible errors:

```json
{
  "success": false,
  "message": "Invalid email or password"
}
```

## Dashboard Auth Handling

After login/register, save token in frontend storage.

Example:

```js
localStorage.setItem("adminToken", response.token);
```

For protected admin APIs, send:

```js
const token = localStorage.getItem("adminToken");

fetch("http://localhost:5000/api/admin/some-protected-api", {
  headers: {
    Authorization: `Bearer ${token}`,
    "Content-Type": "application/json"
  }
});
```

## User Data Shape

User objects returned by user APIs use this shape:

```json
{
  "id": "user_id",
  "name": "User Name",
  "email": "user@example.com",
  "username": "username",
  "profilePhoto": "http://localhost:5000/uploads/users/photo.png",
  "coverPhoto": "http://localhost:5000/uploads/users/cover.png",
  "bio": "Digital creator",
  "links": [
    {
      "title": "Instagram",
      "type": "instagram",
      "url": "https://instagram.com/username"
    }
  ],
  "authProvider": "email",
  "isProfileComplete": true
}
```

Link `type` values:

```text
whatsapp
instagram
facebook
custom
```

## User APIs Available Now

These are mainly for mobile app, but dashboard can use them for testing.

### User Register

```text
POST /api/user/auth/register
```

Request:

```json
{
  "name": "User Name",
  "email": "user@example.com",
  "password": "123456"
}
```

### User Login

```text
POST /api/user/auth/login
```

Request:

```json
{
  "email": "user@example.com",
  "password": "123456"
}
```

### User Google Sign In

```text
POST /api/user/auth/google
```

Google sign in stores image URL directly.

Request:

```json
{
  "name": "User Name",
  "email": "user@gmail.com",
  "googleId": "google_user_id",
  "profilePhoto": "https://lh3.googleusercontent.com/photo.jpg"
}
```

### Get User Profile

```text
GET /api/user/auth/profile
```

Requires user token.

### Update User Profile

```text
PUT /api/user/auth/profile
```

Requires user token.

Profile and cover photos should be sent as base64. Backend saves the image and returns a URL.

Request:

```json
{
  "name": "User Name",
  "bio": "Digital creator",
  "profilePhoto": "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAUA",
  "coverPhoto": "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAUA",
  "links": [
    {
      "title": "Instagram",
      "type": "instagram",
      "url": "https://instagram.com/username"
    },
    {
      "title": "WhatsApp",
      "type": "whatsapp",
      "url": "https://wa.me/923001234567"
    },
    {
      "title": "Website",
      "type": "custom",
      "url": "https://example.com"
    }
  ]
}
```

Response image fields will be URLs:

```json
{
  "profilePhoto": "http://localhost:5000/uploads/users/profile.png",
  "coverPhoto": "http://localhost:5000/uploads/users/cover.png"
}
```

## Frontend Error Handling

Recommended pattern:

```js
const data = await response.json();

if (!data.success) {
  throw new Error(data.message);
}
```

For auth errors, redirect admin to login when status is `401`.

## Notes For Admin Dashboard

### Get Users List

```text
GET /api/admin/users
```

Requires admin token.

Query params:

```text
page=1
limit=10
search=usman
```

Example:

```text
GET /api/admin/users?page=1&limit=10&search=usman
```

Success response:

```json
{
  "success": true,
  "message": "Users fetched successfully",
  "users": [
    {
      "id": "user_id",
      "name": "User Name",
      "email": "user@example.com",
      "username": "username",
      "profilePhoto": "http://localhost:5000/uploads/users/profile.png",
      "coverPhoto": "http://localhost:5000/uploads/users/cover.png",
      "bio": "Digital creator",
      "links": [],
      "authProvider": "email",
      "isProfileComplete": true,
      "createdAt": "2026-06-02T10:00:00.000Z",
      "updatedAt": "2026-06-02T10:00:00.000Z",
      "hasActiveSubscription": true,
      "subscriptionPlan": "monthly",
      "subscriptionExpiryDate": "2026-07-02T10:00:00.000Z",
      "subscription": {
        "id": "subscription_id",
        "planId": "monthly",
        "planName": "Monthly Plan",
        "status": "active",
        "paymentStatus": "paid",
        "paymentMethod": "admin",
        "startDate": "2026-06-02T10:00:00.000Z",
        "endDate": "2026-07-02T10:00:00.000Z"
      }
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 10,
    "totalUsers": 25,
    "totalPages": 3
  }
}
```

### Allot Subscription To User

Admin can manually allot a plan to any user.

```text
POST /api/admin/users/:userId/subscription
```

Requires admin token.

Request:

```json
{
  "planId": "monthly"
}
```

Allowed `planId` values:

```text
monthly
yearly
```

Success response:

```json
{
  "success": true,
  "message": "Subscription allotted successfully",
  "subscription": {
    "id": "subscription_id",
    "planId": "monthly",
    "planName": "Monthly Plan",
    "status": "active",
    "paymentStatus": "paid",
    "paymentMethod": "admin",
    "startDate": "2026-06-02T10:00:00.000Z",
    "endDate": "2026-07-02T10:00:00.000Z"
  }
}
```

### Get Subscriptions List

```text
GET /api/admin/subscriptions
```

Requires admin token.

Query params:

```text
page=1
limit=10
status=active
```

## User Subscription APIs

### Get Plans

```text
GET /api/user/subscription/plans
```

### My Subscription

```text
GET /api/user/subscription/my
```

Requires user token.

### Subscribe

```text
POST /api/user/subscription/subscribe
```

Requires user token. Payment will be integrated later, so current `paymentStatus` is `pending`.

```json
{
  "planId": "yearly"
}
```

### Cancel Subscription

```text
POST /api/user/subscription/cancel
```

Requires user token.

## Next Recommended Admin APIs

Recommended next admin APIs:

```text
GET /api/admin/users/:id
PATCH /api/admin/users/:id/status
DELETE /api/admin/users/:id
GET /api/admin/dashboard/stats
```
