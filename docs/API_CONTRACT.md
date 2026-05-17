# API Contract — Smart Chicken Box (PCB) Backend

> **Version:** 1.0.0
> **Last Updated:** 2026-04-26
> **Audience:** Flutter frontend agent / mobile developer
> **Backend:** FastAPI 0.115 + PostgreSQL 15 + MQTT (Mosquitto 2)

This document is the **single source of truth** for integrating with the PCB IoT backend. Every endpoint, error code, payload constraint, and WebSocket behavior is documented here. When in doubt, this contract wins.

---

## Table of Contents

1. [Base Integration Rules](#1-base-integration-rules)
2. [HTTP Error Dictionary](#2-http-error-dictionary)
3. [REST API Endpoints](#3-rest-api-endpoints)
   - [3.1 Authentication](#31-authentication)
   - [3.2 User Management](#32-user-management)
   - [3.3 Device Management](#33-device-management)
   - [3.4 Admin Dashboard](#34-admin-dashboard)
4. [WebSocket Specifications](#4-websocket-specifications)
5. [Role-Based Access Control (RBAC)](#5-role-based-access-control-rbac)
6. [Pagination Format](#6-pagination-format)
7. [Validation Constraints Reference](#7-validation-constraints-reference)

---

## 1. Base Integration Rules

### Base URL

All REST endpoints are prefixed with `/api`. Use a configurable base URL:

```
{{BASE_URL}}/api
```

**Examples:**
- Development: `http://localhost:8001/api`
- Production: `https://your-domain.com/api`

### Authentication Method

The backend uses **JWT Bearer tokens** (HS256). After authenticating via Firebase, the backend issues its own JWT.

**Header format for all authenticated requests:**

```
Authorization: Bearer <jwt_token>
```

### Token Lifecycle

| Property | Value |
|----------|-------|
| **Algorithm** | HS256 |
| **Lifetime** | 10080 minutes (7 days) |
| **Payload claims** | `sub` (user UUID), `email`, `exp` (expiry timestamp) |
| **Issued by** | `POST /api/auth/firebase/login` |

### Request Tracing

Every response includes an `X-Request-ID` header. Log this value on the client side for debugging.

```
X-Request-ID: a1b2c3d4-e5f6-7890-abcd-ef1234567890
```

### Rate Limiting

All endpoints enforce per-IP rate limits via `slowapi`. When exceeded, the server returns `429`. Limits are documented per-endpoint below.

---

## 2. HTTP Error Dictionary

Every error response from this backend follows one of two JSON structures. Your client **must** handle both.

### Generic Error (all non-422 errors)

```json
{
  "detail": "Human-readable error message"
}
```

The `detail` field is always a **string**.

### Validation Error (422 only)

```json
{
  "detail": [
    {
      "loc": ["body", "field_name"],
      "msg": "Human-readable validation message",
      "type": "error_type"
    }
  ]
}
```

The `detail` field is an **array of objects**. Each object contains `loc` (field path), `msg` (message), and `type` (error classifier).

### Error Code Reference

| HTTP Code | Meaning in This Backend | When It Happens | Client Action |
|:---------:|------------------------|-----------------|---------------|
| **400** | Bad Request | Invalid business logic (e.g., claiming an already-claimed device, assigning yourself, duplicate MAC address) | Show `detail` message to user |
| **401** | Unauthorized | Missing `Authorization` header, expired JWT, invalid JWT, user not found in DB, **account deactivated** (via JWT check) | Redirect to login screen. Clear stored token. |
| **403** | Forbidden | Account deactivated (on Firebase login), insufficient role permissions (e.g., `user` trying to claim a device, `viewer` trying to control a device) | Show `detail` message. Do **not** retry. |
| **404** | Not Found | Resource does not exist **or** the user lacks access to it. The backend intentionally returns 404 instead of 403 for device access to prevent enumeration. | Show "not found" message |
| **422** | Validation Error | Pydantic constraint violated (e.g., `id_token` exceeds 4096 chars, `full_name` is empty, MAC address format invalid, `days` param out of range 1-90) | Parse the `detail` array. Highlight invalid fields in the UI. |
| **429** | Rate Limit Exceeded | Too many requests from the same IP within the rate window | Implement exponential backoff. Show "please wait" message. |
| **500** | Internal Server Error | Unhandled exception. The backend **never** leaks internal details — the message is always generic. | Show generic error. Retry once, then fail gracefully. |
| **503** | Service Unavailable | Database is unreachable (returned by `/api/health` only) | Show "server maintenance" message |

### Important: 401 vs 403 Distinction

- **401** = "I don't know who you are" (token problem)
- **403** = "I know who you are, but you can't do this" (permission problem)

On **login** (`POST /auth/firebase/login`), a deactivated account returns **403**. On **all other endpoints**, a deactivated account returns **401** (because the JWT dependency rejects it before the route handler runs).

---

## 3. REST API Endpoints

### 3.1 Authentication

#### `POST /api/auth/firebase/login`

Exchange a Firebase `id_token` for a local JWT. This is the **only unauthenticated endpoint** (besides `/api/health`).

| Property | Value |
|----------|-------|
| **Rate Limit** | 10/minute |
| **Auth Required** | No |
| **Minimum Role** | None |

**Request Body:**

```json
{
  "id_token": "eyJhbGciOiJSUzI1NiIs..."
}
```

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id_token` | string | **Required**, max 4096 chars | Firebase ID token from `firebase_auth.currentUser.getIdToken()` |

**Success Response (200):**

```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIs...",
  "token_type": "bearer",
  "user_info": {
    "email": "user@example.com",
    "full_name": "John Doe",
    "picture": "https://lh3.googleusercontent.com/...",
    "role": "user"
  }
}
```

| Field | Type | Description |
|-------|------|-------------|
| `access_token` | string | JWT to use in `Authorization: Bearer <token>` for all subsequent requests |
| `token_type` | string | Always `"bearer"` |
| `user_info.email` | string | User's email from Firebase |
| `user_info.full_name` | string | Display name from Firebase, or email prefix if empty |
| `user_info.picture` | string | Profile photo URL from Firebase (may be empty) |
| `user_info.role` | string | One of: `super_admin`, `admin`, `operator`, `viewer`, `user` |

**Error Responses:**

| Code | Detail | Cause |
|:----:|--------|-------|
| 401 | `"Token Firebase tidak valid."` | Malformed or tampered Firebase token |
| 401 | `"Token Firebase sudah kedaluwarsa."` | Firebase token expired — call `getIdToken(true)` to refresh |
| 403 | `"Akun telah dinonaktifkan. Hubungi admin."` | Account was deactivated by an admin |
| 422 | Validation array | `id_token` missing or exceeds 4096 chars |
| 429 | Rate limit exceeded | More than 10 login attempts per minute from same IP |

**Behavior Notes:**
- First-time users are **auto-registered** with role `user`.
- If the email matches the `INITIAL_ADMIN_EMAIL` environment variable, the user is auto-promoted to `super_admin`.
- Race conditions on first login are handled gracefully (concurrent requests won't create duplicate users).

---

### 3.2 User Management

All endpoints in this group require `Authorization: Bearer <token>`.

---

#### `GET /api/users/me`

Get the authenticated user's profile.

| Property | Value |
|----------|-------|
| **Rate Limit** | 60/minute |
| **Auth Required** | Yes |
| **Minimum Role** | Any authenticated user |

**Success Response (200):**

```json
{
  "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "email": "user@example.com",
  "full_name": "John Doe",
  "picture": "https://lh3.googleusercontent.com/...",
  "provider": "firebase",
  "is_active": true,
  "role": "admin"
}
```

| Field | Type | Description |
|-------|------|-------------|
| `id` | UUID | Unique user identifier |
| `email` | string | User's email address |
| `full_name` | string or null | Display name |
| `picture` | string or null | Profile photo URL |
| `provider` | string | Always `"firebase"` |
| `is_active` | boolean | Account status |
| `role` | string | One of: `super_admin`, `admin`, `operator`, `viewer`, `user` |

---

#### `PATCH /api/users/me`

Update the authenticated user's display name.

| Property | Value |
|----------|-------|
| **Rate Limit** | 10/minute |
| **Auth Required** | Yes |
| **Minimum Role** | Any authenticated user |

**Request Body:**

```json
{
  "full_name": "New Display Name"
}
```

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `full_name` | string | **Required**, 1-100 chars (trimmed) | New display name |

**Success Response (200):** Same schema as `GET /api/users/me`.

**Error Responses:**

| Code | Detail | Cause |
|:----:|--------|-------|
| 422 | Validation array | Name is empty after trimming, or exceeds 100 chars |

---

#### `DELETE /api/users/me`

Permanently delete the authenticated user's account. **Irreversible.**

| Property | Value |
|----------|-------|
| **Rate Limit** | 5/minute |
| **Auth Required** | Yes |
| **Minimum Role** | Any authenticated user |

**Request Body:** None

**Success Response (200):**

```json
{
  "message": "Akun berhasil dihapus dari database lokal"
}
```

**Side Effects:**
- All device assignments for this user are deleted.
- All devices owned by this user are unclaimed (reverted to unowned state).

---

#### `PATCH /api/users/{user_id}/role`

Change another user's role. Enforces strict hierarchy rules.

| Property | Value |
|----------|-------|
| **Rate Limit** | 10/minute |
| **Auth Required** | Yes |
| **Minimum Role** | `admin` |

**Path Parameters:**

| Parameter | Type | Description |
|-----------|------|-------------|
| `user_id` | UUID | Target user's ID |

**Request Body:**

```json
{
  "role": "operator"
}
```

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `role` | string | **Required**, one of: `super_admin`, `admin`, `operator`, `viewer`, `user` | New role to assign |

**Success Response (200):** Same schema as `GET /api/users/me` (returns updated user).

**Error Responses:**

| Code | Detail | Cause |
|:----:|--------|-------|
| 400 | `"Tidak bisa mengubah role diri sendiri!"` | Attempted to change own role |
| 400 | `"Tidak bisa mengubah role Super Admin lain..."` | Super Admin tried to demote another Super Admin |
| 403 | `"Admin hanya bisa mengatur role: operator, viewer, user"` | Admin tried to promote to admin/super_admin |
| 403 | `"Tidak bisa mengubah role Super Admin atau Admin lain."` | Admin tried to modify a higher-ranked user |
| 404 | `"User tidak ditemukan"` | Target user_id does not exist |

**Hierarchy Rules:**

| Actor | Can Set Roles | Cannot Touch |
|-------|--------------|-------------|
| **super_admin** | `super_admin`, `admin`, `operator`, `viewer`, `user` | Cannot demote another `super_admin` |
| **admin** | `operator`, `viewer`, `user` | Cannot touch `admin` or `super_admin` users |

---

#### `POST /api/users/me/fcm-token`

Register an FCM push notification token. Called on login and on token refresh.

| Property | Value |
|----------|-------|
| **Rate Limit** | 20/minute |
| **Auth Required** | Yes |
| **Minimum Role** | Any authenticated user |

**Request Body:**

```json
{
  "token": "dGVzdC1mY20tdG9rZW4tZm9yLWRldmljZQ...",
  "device_info": "Samsung Galaxy S24 - Android 15"
}
```

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `token` | string | **Required**, 10-500 chars (trimmed) | FCM registration token |
| `device_info` | string or null | Optional, max 200 chars | Human-readable device description |

**Success Response (200):**

```json
{
  "status": "success",
  "message": "FCM token berhasil didaftarkan"
}
```

**Behavior Notes:**
- Maximum **10 FCM tokens per user** (10 physical devices). When the limit is reached, the oldest token is automatically deleted.
- If the same token is registered by a different user, it is **reassigned** to the new user (device changed hands).

---

#### `DELETE /api/users/me/fcm-token`

Unregister an FCM token. Call this on **logout**.

| Property | Value |
|----------|-------|
| **Rate Limit** | 20/minute |
| **Auth Required** | Yes |
| **Minimum Role** | Any authenticated user |

**Request Body:**

```json
{
  "token": "dGVzdC1mY20tdG9rZW4tZm9yLWRldmljZQ...",
  "device_info": null
}
```

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `token` | string | **Required**, 10-500 chars | The FCM token to remove |
| `device_info` | string or null | Optional (ignored) | Not used for deletion, but required by schema |

**Success Response (200):**

```json
{
  "status": "success",
  "message": "FCM token berhasil dihapus"
}
```

> If the token was not found, the response is still 200 with message `"FCM token tidak ditemukan"`.

---

### 3.3 Device Management

All endpoints in this group require `Authorization: Bearer <token>`.
All device IDs are **UUIDs**.

---

#### `POST /api/devices/register`

Register a new device MAC address into the system. The device starts as **unclaimed**.

| Property | Value |
|----------|-------|
| **Rate Limit** | 20/minute |
| **Auth Required** | Yes |
| **Minimum Role** | `super_admin` |

**Request Body:**

```json
{
  "mac_address": "44:1D:64:BE:22:08"
}
```

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `mac_address` | string | **Required**, format `XX:XX:XX:XX:XX:XX` or `XXXXXXXXXXXX` | Device MAC address. Auto-normalized to uppercase with colons. |

**Success Response (201):**

```json
{
  "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "mac_address": "44:1D:64:BE:22:08",
  "name": null,
  "user_id": null,
  "last_heartbeat": null,
  "is_online": false
}
```

**Error Responses:**

| Code | Detail | Cause |
|:----:|--------|-------|
| 400 | `"Perangkat dengan MAC Address tersebut sudah terdaftar!"` | Duplicate MAC address |
| 403 | `"Akses ditolak! Endpoint ini khusus Super Admin."` | Caller is not `super_admin` |
| 422 | Validation array | Invalid MAC format |

---

#### `POST /api/devices/claim`

Claim an unclaimed device via QR code scan. Sets the caller as the device owner.

| Property | Value |
|----------|-------|
| **Rate Limit** | 10/minute |
| **Auth Required** | Yes |
| **Minimum Role** | `admin` |

**Request Body:**

```json
{
  "mac_address": "44:1D:64:BE:22:08",
  "name": "Kandang Utara"
}
```

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `mac_address` | string | **Required**, format `XX:XX:XX:XX:XX:XX` or `XXXXXXXXXXXX` | MAC from QR code |
| `name` | string | **Required**, 1-100 chars (trimmed) | Human-readable name for the coop |

**Success Response (200):** Same schema as device register (with `user_id` and `name` populated).

**Error Responses:**

| Code | Detail | Cause |
|:----:|--------|-------|
| 400 | `"Device ini sudah diklaim oleh pengguna lain!"` | Device already has an owner |
| 403 | `"Hanya Admin yang bisa mengklaim device."` | Caller role is below `admin` |
| 404 | `"Device tidak dikenali!..."` | MAC address not found in system |

**Concurrency Note:** Uses `SELECT ... FOR UPDATE` to prevent race conditions when two admins try to claim the same device simultaneously.

---

#### `GET /api/devices/`

List devices accessible to the current user. Results vary by role.

| Property | Value |
|----------|-------|
| **Rate Limit** | 30/minute |
| **Auth Required** | Yes |
| **Minimum Role** | Any authenticated user |
| **Response Format** | [Paginated](#6-pagination-format) |

**Query Parameters:**

| Parameter | Type | Default | Constraints | Description |
|-----------|------|---------|-------------|-------------|
| `page` | int | 1 | ge=1 | Page number |
| `limit` | int | 20 | 1-100 | Items per page |

**Role-Based Filtering:**

| Role | Sees |
|------|------|
| `super_admin` | All devices in the system |
| `admin` | Only devices they own |
| `operator` | Only devices assigned to them |
| `viewer` | Only devices assigned to them |
| `user` | Empty list (no device access) |

**Success Response (200):**

```json
{
  "data": [
    {
      "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
      "mac_address": "44:1D:64:BE:22:08",
      "name": "Kandang Utara",
      "user_id": "b2c3d4e5-f6a7-8901-bcde-f12345678901",
      "last_heartbeat": "2026-04-26T10:30:00Z",
      "is_online": true
    }
  ],
  "total": 5,
  "page": 1,
  "limit": 20,
  "total_pages": 1
}
```

**Device Object Fields:**

| Field | Type | Description |
|-------|------|-------------|
| `id` | UUID | Unique device identifier |
| `mac_address` | string | Hardware MAC address |
| `name` | string or null | Human-readable name (null if unclaimed) |
| `user_id` | UUID or null | Owner's user ID (null if unclaimed) |
| `last_heartbeat` | ISO 8601 or null | Last MQTT message timestamp |
| `is_online` | boolean | **Computed field.** `true` if `last_heartbeat` is within 120 seconds of now. |

---

#### `GET /api/devices/unclaimed`

List devices that have not been claimed by any admin.

| Property | Value |
|----------|-------|
| **Rate Limit** | 30/minute |
| **Auth Required** | Yes |
| **Minimum Role** | `admin` |
| **Response Format** | [Paginated](#6-pagination-format) |

**Query Parameters:** Same as `GET /api/devices/` (`page`, `limit`).

**Success Response (200):** Paginated list of device objects where `user_id` is `null`.

---

#### `GET /api/devices/all`

List all devices (claimed + unclaimed). Scope varies by admin level.

| Property | Value |
|----------|-------|
| **Rate Limit** | 30/minute |
| **Auth Required** | Yes |
| **Minimum Role** | `admin` |
| **Response Format** | [Paginated](#6-pagination-format) |

**Query Parameters:** Same as `GET /api/devices/` (`page`, `limit`).

**Role-Based Filtering:**

| Role | Sees |
|------|------|
| `super_admin` | All devices |
| `admin` | Own devices + unclaimed devices |

---

#### `PATCH /api/devices/{device_id}`

Rename a device.

| Property | Value |
|----------|-------|
| **Rate Limit** | 20/minute |
| **Auth Required** | Yes |
| **Minimum Role** | `admin` (owner) or `super_admin` |

**Path Parameters:**

| Parameter | Type | Description |
|-----------|------|-------------|
| `device_id` | UUID | Target device ID |

**Request Body:**

```json
{
  "name": "Kandang Selatan"
}
```

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `name` | string | **Required**, 1-100 chars (trimmed) | New device name |

**Success Response (200):** Device object with updated name.

---

#### `DELETE /api/devices/{device_id}`

Permanently delete a device and **all** associated data. **Irreversible.**

| Property | Value |
|----------|-------|
| **Rate Limit** | 10/minute |
| **Auth Required** | Yes |
| **Minimum Role** | `super_admin` |

**Path Parameters:**

| Parameter | Type | Description |
|-----------|------|-------------|
| `device_id` | UUID | Target device ID |

**Request Body:** None

**Success Response (200):**

```json
{
  "status": "success",
  "message": "Device 44:1D:64:BE:22:08 berhasil dihapus beserta 1500 sensor logs dan 3 assignments."
}
```

**Side Effects:**
- All sensor logs for this device are deleted (CASCADE).
- All user assignments for this device are deleted (CASCADE).
- All active WebSocket connections streaming this device are closed with code **4004**.

---

#### `GET /api/devices/{device_id}/logs`

Retrieve historical sensor data for a device.

| Property | Value |
|----------|-------|
| **Rate Limit** | 60/minute |
| **Auth Required** | Yes |
| **Minimum Role** | Any role with device access |
| **Response Format** | [Paginated](#6-pagination-format) |

**Path Parameters:**

| Parameter | Type | Description |
|-----------|------|-------------|
| `device_id` | UUID | Target device ID |

**Query Parameters:**

| Parameter | Type | Default | Constraints | Description |
|-----------|------|---------|-------------|-------------|
| `page` | int | 1 | ge=1 | Page number |
| `limit` | int | 20 | 1-100 | Items per page |

**Success Response (200):**

```json
{
  "data": [
    {
      "id": 12345,
      "temperature": 30.5,
      "humidity": 75.0,
      "ammonia": 12.5,
      "light_level": 1,
      "is_alert": false,
      "alert_message": null,
      "timestamp": "2026-04-26T10:30:00Z"
    }
  ],
  "total": 500,
  "page": 1,
  "limit": 20,
  "total_pages": 25
}
```

**Sensor Log Fields:**

| Field | Type | Description |
|-------|------|-------------|
| `id` | integer | Auto-increment log ID |
| `temperature` | float | Temperature in Celsius |
| `humidity` | float | Relative humidity percentage |
| `ammonia` | float | Ammonia concentration in ppm |
| `light_level` | integer or null | LDR reading: `0` = dark, `1` = bright. `null` for legacy data. |
| `is_alert` | boolean | Whether this reading triggered an alert |
| `alert_message` | string or null | Alert description (e.g., "Suhu terlalu tinggi: 36.5°C") |
| `timestamp` | ISO 8601 | When the reading was recorded |

**Data is sorted by `timestamp DESC` (newest first).**

---

#### `POST /api/devices/{device_id}/control`

Send a control command to a device via MQTT.

| Property | Value |
|----------|-------|
| **Rate Limit** | 30/minute |
| **Auth Required** | Yes |
| **Minimum Role** | `operator` (assigned), `admin` (owner), or `super_admin` |

**Path Parameters:**

| Parameter | Type | Description |
|-----------|------|-------------|
| `device_id` | UUID | Target device ID |

**Request Body:**

```json
{
  "component": "kipas",
  "state": true
}
```

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `component` | string | **Required**, one of: `kipas`, `lampu`, `pompa`, `pakan_otomatis`, `exhaust_fan` | Hardware component to control |
| `state` | boolean | **Required** | `true` = ON, `false` = OFF |

**Component Reference:**

| Value | English | Description |
|-------|---------|-------------|
| `kipas` | Fan | Ventilation fan |
| `lampu` | Light | Coop lighting |
| `pompa` | Pump | Water pump |
| `pakan_otomatis` | Auto Feeder | Automatic feeding system |
| `exhaust_fan` | Exhaust Fan | Exhaust fan for ammonia/heat ventilation |

**Success Response (200):**

```json
{
  "status": "success",
  "message": "Perintah kipas dikirim ke Kandang Utara"
}
```

**Error Responses:**

| Code | Detail | Cause |
|:----:|--------|-------|
| 403 | `"Akses ditolak! Viewer hanya bisa melihat data..."` | `viewer` role cannot control devices |
| 403 | `"Akses ditolak. Hubungi admin..."` | `user` role has no device access |
| 500 | `"Gagal mengirim perintah ke device."` | MQTT broker unreachable |

---

#### `GET /api/devices/{device_id}/alerts`

Retrieve alert history for a device (sensor logs where `is_alert = true`).

| Property | Value |
|----------|-------|
| **Rate Limit** | 60/minute |
| **Auth Required** | Yes |
| **Minimum Role** | Any role with device access |
| **Response Format** | [Paginated](#6-pagination-format) |

**Path & Query Parameters:** Same as `GET /api/devices/{device_id}/logs`.

**Success Response (200):** Same schema as sensor logs, but filtered to alerts only.

---

#### `GET /api/devices/{device_id}/stats/daily`

Get daily aggregated statistics for a device.

| Property | Value |
|----------|-------|
| **Rate Limit** | 30/minute |
| **Auth Required** | Yes |
| **Minimum Role** | Any role with device access |

**Path Parameters:**

| Parameter | Type | Description |
|-----------|------|-------------|
| `device_id` | UUID | Target device ID |

**Query Parameters:**

| Parameter | Type | Default | Constraints | Description |
|-----------|------|---------|-------------|-------------|
| `days` | int | 7 | 1-90 | Number of days to look back |

**Success Response (200):**

```json
{
  "device_id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "device_name": "Kandang Utara",
  "period_start": "2026-04-20",
  "period_end": "2026-04-26",
  "total_days": 7,
  "statistics": [
    {
      "date": "2026-04-26",
      "avg_temperature": 28.45,
      "min_temperature": 25.10,
      "max_temperature": 31.80,
      "avg_humidity": 72.30,
      "avg_ammonia": 12.55,
      "data_points": 288,
      "alert_count": 3,
      "status": "Normal"
    }
  ]
}
```

**Daily Stats Fields:**

| Field | Type | Description |
|-------|------|-------------|
| `date` | date (YYYY-MM-DD) | The calendar day |
| `avg_temperature` | float | Average temperature (rounded to 2 decimals) |
| `min_temperature` | float | Minimum temperature |
| `max_temperature` | float | Maximum temperature |
| `avg_humidity` | float | Average humidity percentage |
| `avg_ammonia` | float | Average ammonia ppm |
| `data_points` | integer | Number of sensor readings that day |
| `alert_count` | integer | Number of alert-triggering readings |
| `status` | string | **Computed.** `"Normal"` (25-30C), `"Waspada"` (20-25 or 30-35C), `"Bahaya"` (below 20 or above 35C) |

---

#### `POST /api/devices/{device_id}/unclaim`

Release ownership of a device. Reverts it to unclaimed state.

| Property | Value |
|----------|-------|
| **Rate Limit** | 10/minute |
| **Auth Required** | Yes |
| **Minimum Role** | `admin` (owner) or `super_admin` |

**Path Parameters:**

| Parameter | Type | Description |
|-----------|------|-------------|
| `device_id` | UUID | Target device ID |

**Request Body:** None

**Success Response (200):**

```json
{
  "status": "success",
  "message": "Device berhasil di-unclaim."
}
```

**Side Effects:**
- All user assignments for this device are deleted.
- Device `name` is reset to `null`.
- All active WebSocket connections for this device are closed.

---

#### `GET /api/devices/{device_id}/status`

Check if a device is online or offline.

| Property | Value |
|----------|-------|
| **Rate Limit** | 60/minute |
| **Auth Required** | Yes |
| **Minimum Role** | Any role with device access |

**Path Parameters:**

| Parameter | Type | Description |
|-----------|------|-------------|
| `device_id` | UUID | Target device ID |

**Success Response (200):**

```json
{
  "device_id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "is_online": true,
  "last_seen": "2026-04-26T10:30:00Z",
  "seconds_since_last_seen": 45
}
```

| Field | Type | Description |
|-------|------|-------------|
| `device_id` | UUID | Device identifier |
| `is_online` | boolean | `true` if last heartbeat within 120 seconds |
| `last_seen` | ISO 8601 or null | Last heartbeat timestamp (`null` if device never connected) |
| `seconds_since_last_seen` | integer | Seconds since last heartbeat |

> If the device has never connected, `last_seen` is `null` and `message` is `"Belum ada koneksi"`.

---

#### `POST /api/devices/{device_id}/assign`

Assign a user (operator or viewer) to a device.

| Property | Value |
|----------|-------|
| **Rate Limit** | 20/minute |
| **Auth Required** | Yes |
| **Minimum Role** | `admin` (owner) or `super_admin` |

**Path Parameters:**

| Parameter | Type | Description |
|-----------|------|-------------|
| `device_id` | UUID | Target device ID |

**Request Body:**

```json
{
  "user_id": "b2c3d4e5-f6a7-8901-bcde-f12345678901",
  "role": "operator"
}
```

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `user_id` | UUID | **Required** | Target user to assign |
| `role` | string | **Required**, one of: `operator`, `viewer` | Access level to grant |

**Success Response (200):**

```json
{
  "id": "c3d4e5f6-a7b8-9012-cdef-123456789012",
  "device_id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "user_id": "b2c3d4e5-f6a7-8901-bcde-f12345678901",
  "user_email": "operator@example.com",
  "user_name": "Operator One",
  "role": "operator",
  "assigned_by": "d4e5f6a7-b8c9-0123-def0-1234567890ab",
  "created_at": "2026-04-26T10:30:00Z"
}
```

**Error Responses:**

| Code | Detail | Cause |
|:----:|--------|-------|
| 400 | `"Tidak bisa assign diri sendiri."` | `user_id` matches the caller |
| 400 | `"Tidak perlu assign Admin/Super Admin..."` | Target is already admin+ |
| 400 | `"User sudah di-assign ke device ini."` | Duplicate assignment |
| 404 | `"User tidak ditemukan."` | Target user_id does not exist |

**Behavior Note:** If the target user's current role is `user` (default), they are **automatically promoted** to the assigned role (`operator` or `viewer`).

---

#### `DELETE /api/devices/{device_id}/assign/{user_id}`

Remove a user's assignment from a device.

| Property | Value |
|----------|-------|
| **Rate Limit** | 20/minute |
| **Auth Required** | Yes |
| **Minimum Role** | `admin` (owner) or `super_admin` |

**Path Parameters:**

| Parameter | Type | Description |
|-----------|------|-------------|
| `device_id` | UUID | Target device ID |
| `user_id` | UUID | User to unassign |

**Request Body:** None

**Success Response (200):**

```json
{
  "status": "success",
  "message": "User berhasil di-unassign dari device."
}
```

**Error Responses:**

| Code | Detail | Cause |
|:----:|--------|-------|
| 404 | `"Assignment tidak ditemukan."` | No matching assignment exists |

---

#### `GET /api/devices/{device_id}/assignments`

List all users assigned to a device.

| Property | Value |
|----------|-------|
| **Rate Limit** | 30/minute |
| **Auth Required** | Yes |
| **Minimum Role** | `admin` (owner) or `super_admin` |
| **Response Format** | Array (not paginated — bounded by business logic) |

**Path Parameters:**

| Parameter | Type | Description |
|-----------|------|-------------|
| `device_id` | UUID | Target device ID |

**Success Response (200):**

```json
[
  {
    "id": "c3d4e5f6-a7b8-9012-cdef-123456789012",
    "device_id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
    "user_id": "b2c3d4e5-f6a7-8901-bcde-f12345678901",
    "user_email": "operator@example.com",
    "user_name": "Operator One",
    "role": "operator",
    "assigned_by": "d4e5f6a7-b8c9-0123-def0-1234567890ab",
    "created_at": "2026-04-26T10:30:00Z"
  }
]
```

> **Note:** This endpoint returns a plain JSON array, not a paginated wrapper. The number of assignments per device is naturally small (typically < 20).

---

### 3.4 Admin Dashboard

All endpoints in this group require `Authorization: Bearer <token>` and `admin` role or higher.

---

#### `GET /api/admin/stats`

Dashboard overview with aggregated counts.

| Property | Value |
|----------|-------|
| **Rate Limit** | 30/minute |
| **Auth Required** | Yes |
| **Minimum Role** | `admin` |

**Request Body:** None

**Success Response (200):**

```json
{
  "total_users": 42,
  "total_super_admins": 1,
  "total_admins": 3,
  "total_operators": 10,
  "total_viewers": 8,
  "total_devices": 15,
  "total_devices_claimed": 12,
  "total_devices_unclaimed": 3,
  "total_devices_online": 9,
  "total_assignments": 25
}
```

| Field | Type | Description |
|-------|------|-------------|
| `total_users` | integer | Total registered users across all roles |
| `total_super_admins` | integer | Users with `super_admin` role |
| `total_admins` | integer | Users with `admin` role |
| `total_operators` | integer | Users with `operator` role |
| `total_viewers` | integer | Users with `viewer` role |
| `total_devices` | integer | Total devices in the system |
| `total_devices_claimed` | integer | Devices with an owner |
| `total_devices_unclaimed` | integer | Devices without an owner |
| `total_devices_online` | integer | Devices with heartbeat within 120 seconds |
| `total_assignments` | integer | Total device-user assignments |

---

#### `GET /api/admin/users`

List all users with pagination.

| Property | Value |
|----------|-------|
| **Rate Limit** | 30/minute |
| **Auth Required** | Yes |
| **Minimum Role** | `admin` |
| **Response Format** | [Paginated](#6-pagination-format) |

**Query Parameters:**

| Parameter | Type | Default | Constraints | Description |
|-----------|------|---------|-------------|-------------|
| `page` | int | 1 | ge=1 | Page number |
| `limit` | int | 20 | 1-100 | Items per page |

**Success Response (200):** Paginated list of user objects (same schema as `GET /api/users/me`). Sorted by `created_at DESC`.

---

#### `POST /api/admin/sync-firebase-users`

Sync all Firebase Auth users into the local PostgreSQL database.

| Property | Value |
|----------|-------|
| **Rate Limit** | 5/minute |
| **Auth Required** | Yes |
| **Minimum Role** | `super_admin` |

**Request Body:** None

**Success Response (200):**

```json
{
  "synced_count": 5,
  "skipped_count": 37,
  "failed_count": 0,
  "synced": ["new1@example.com", "new2@example.com"],
  "skipped": ["existing@example.com"],
  "failed": []
}
```

| Field | Type | Description |
|-------|------|-------------|
| `synced_count` | integer | Number of new users created |
| `skipped_count` | integer | Users already in local DB |
| `failed_count` | integer | Users that failed to sync |
| `synced` | string[] | Emails of newly created users |
| `skipped` | string[] | Emails of existing users |
| `failed` | object[] | `[{"email": "...", "error": "..."}]` |

---

#### `POST /api/admin/cleanup-logs`

Delete old sensor logs beyond the retention period. Executes in batches of 1000 rows.

| Property | Value |
|----------|-------|
| **Rate Limit** | 5/minute |
| **Auth Required** | Yes |
| **Minimum Role** | `super_admin` |

**Query Parameters:**

| Parameter | Type | Default | Constraints | Description |
|-----------|------|---------|-------------|-------------|
| `days` | int | `SENSOR_LOG_RETENTION_DAYS` env var (365) | ge=1 | Delete logs older than N days |

**Request Body:** None

**Success Response (200):**

```json
{
  "status": "success",
  "message": "1500 sensor logs berhasil dihapus.",
  "deleted_count": 1500,
  "retention_days": 365,
  "cutoff_date": "2025-04-26T00:00:00+00:00"
}
```

**Error Responses:**

| Code | Detail | Cause |
|:----:|--------|-------|
| 400 | `"Data retention di-disable (SENSOR_LOG_RETENTION_DAYS=0)..."` | Retention is disabled in env config |

---

#### `GET /api/health`

Health check endpoint. **No authentication required.**

| Property | Value |
|----------|-------|
| **Rate Limit** | 60/minute |
| **Auth Required** | No |

**Success Response (200):**

```json
{
  "status": "healthy",
  "database_alive": true
}
```

**Failure Response (503):**

```json
{
  "status": "unhealthy",
  "database_alive": false
}
```

---

## 4. WebSocket Specifications

### Connection URL

```
ws://{{BASE_URL}}/api/ws/devices/{device_id}?token={jwt_token}
```

**Or with TLS:**

```
wss://{{BASE_URL}}/api/ws/devices/{device_id}?token={jwt_token}
```

### Connection Parameters

| Parameter | Location | Type | Description |
|-----------|----------|------|-------------|
| `device_id` | URL path | UUID | The device to stream data from |
| `token` | Query string | string | JWT Bearer token (same token used for REST API) |

> **Security Note:** The JWT is sent via query parameter because the WebSocket protocol does not support custom HTTP headers during the handshake. The token will be visible in server logs and browser history. This is acceptable for this project's scope.

### Connection Lifecycle

```
Client                          Server
  |                               |
  |--- WebSocket Upgrade -------->|
  |                               |  (accept connection)
  |<-- Connection Accepted -------|
  |                               |  (authenticate JWT)
  |                               |  (check device access)
  |                               |
  |    [If auth fails]            |
  |<-- Close(4001) ---------------|  "Token tidak valid"
  |                               |
  |    [If access denied]         |
  |<-- Close(4003) ---------------|  "Akses ditolak"
  |                               |
  |    [If auth + access OK]      |
  |                               |  (poll DB every 3 seconds)
  |<-- sensor_data JSON ----------|  (only when new data available)
  |<-- sensor_data JSON ----------|
  |                               |
  |    [If device deleted]        |
  |<-- Close(4004) ---------------|  "Device telah dihapus"
  |                               |
  |    [If device unclaimed]      |
  |<-- Close(4004) ---------------|  "Device di-unclaim"
  |                               |
  |--- Client Disconnect -------->|
  |                               |  (cleanup connection)
```

### Server-Sent Message Format

The server sends JSON messages every **3 seconds** (only when new data is available — deduplication by `log_id`).

```json
{
  "type": "sensor_data",
  "device_id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "device_name": "Kandang Utara",
  "is_online": true,
  "subscribers": 2,
  "latest": {
    "id": 12345,
    "temperature": 30.5,
    "humidity": 75.0,
    "ammonia": 12.5,
    "light_level": 1,
    "is_alert": false,
    "alert_message": null,
    "timestamp": "2026-04-26T10:30:00"
  }
}
```

**Message Fields:**

| Field | Type | Description |
|-------|------|-------------|
| `type` | string | Always `"sensor_data"` |
| `device_id` | string | UUID of the device |
| `device_name` | string or null | Human-readable device name |
| `is_online` | boolean | Whether the device heartbeat is within 120 seconds |
| `subscribers` | integer | Number of active WebSocket connections for this device |
| `latest.id` | integer | Sensor log ID |
| `latest.temperature` | float | Temperature in Celsius |
| `latest.humidity` | float | Relative humidity percentage |
| `latest.ammonia` | float | Ammonia concentration in ppm |
| `latest.light_level` | integer or null | LDR reading: `0` = dark, `1` = bright |
| `latest.is_alert` | boolean | Whether this reading triggered an alert |
| `latest.alert_message` | string or null | Alert description |
| `latest.timestamp` | string | ISO 8601 timestamp of the reading |

### WebSocket Close Codes

| Code | Meaning | Client Action |
|:----:|---------|---------------|
| **4001** | Invalid or expired JWT token | Redirect to login. Obtain a new token. |
| **4003** | Access denied to this device | Show "access denied" message. Do not reconnect. |
| **4004** | Device was deleted or unclaimed | Show "device removed" message. Navigate away from device screen. |
| **1000** | Normal closure | Client-initiated disconnect. No action needed. |
| **1006** | Abnormal closure (network drop) | Implement reconnection with exponential backoff. |

### Reconnection Strategy

The server does **not** send ping/pong frames. If the connection drops:

1. Wait 1 second, then reconnect.
2. If reconnection fails, double the wait time (2s, 4s, 8s...).
3. Cap the maximum wait at 30 seconds.
4. On successful reconnection, reset the backoff timer.
5. If the server returns close code **4001**, **4003**, or **4004**, do **not** reconnect.

---
