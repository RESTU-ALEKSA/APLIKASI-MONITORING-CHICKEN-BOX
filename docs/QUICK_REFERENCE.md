# Quick Reference — Common Operations

## 🔐 Authentication

### Login
```dart
import 'services/auth_service.dart';
import 'core/network/api_exception.dart';

final authService = AuthService();

try {
  final response = await authService.login(firebaseIdToken);
  print('Logged in as: ${response.userInfo.email}');
} on UnauthorizedException catch (e) {
  print('Auth failed: ${e.message}');
}
```

### Logout
```dart
await authService.logout();
```

### Check if authenticated
```dart
final isAuth = await authService.isAuthenticated();
```

### Get current user
```dart
final user = await authService.getCurrentUser();
if (user != null) {
  print('Email: ${user.email}');
  print('Role: ${user.role}');
}
```

---

## 📡 Making API Calls

### GET Request
```dart
import 'package:dio/dio.dart';
import 'core/network/dio_client.dart';
import 'constants/api_config.dart';

final dio = DioClient().dio;

try {
  final response = await dio.get(ApiConfig.devicesUrl);
  final devices = response.data['data'];
} on DioException catch (e) {
  if (e.error is ApiException) {
    print('Error: ${(e.error as ApiException).message}');
  }
}
```

### POST Request
```dart
final response = await dio.post(
  ApiConfig.deviceControlUrl(deviceId),
  data: {
    'component': 'kipas',
    'state': true,
  },
);
```

### PATCH Request
```dart
final response = await dio.patch(
  ApiConfig.deviceUpdateUrl(deviceId),
  data: {'name': 'Kandang Baru'},
);
```

### DELETE Request
```dart
final response = await dio.delete(
  ApiConfig.deviceDeleteUrl(deviceId),
);
```

---

## 🛡️ Error Handling

### Handle all error types
```dart
try {
  await deviceService.getDevices();
} on ValidationException catch (e) {
  // 422 - Field validation errors
  print(e.allMessages);
} on UnauthorizedException catch (e) {
  // 401 - Auto-logout triggered
  print(e.message);
} on ForbiddenException catch (e) {
  // 403 - Permission denied
  print(e.message);
} on NotFoundException catch (e) {
  // 404 - Resource not found
  print(e.message);
} on RateLimitException catch (e) {
  // 429 - Too many requests
  print(e.message);
} on NetworkException catch (e) {
  // Network error
  print(e.message);
} on ApiException catch (e) {
  // Other API errors
  print(e.message);
}
```

### Get field-specific validation errors
```dart
try {
  await authService.login(token);
} on ValidationException catch (e) {
  final tokenErrors = e.getFieldErrors('id_token');
  for (var error in tokenErrors) {
    print('${error.field}: ${error.msg}');
  }
}
```

---

## 👤 Role Checking

```dart
final userInfo = loginResponse.userInfo;

// Check admin privileges
if (userInfo.isAdmin) {
  // Show admin panel
}

// Check super admin
if (userInfo.isSuperAdmin) {
  // Show super admin features
}

// Check device control permissions
if (userInfo.canControlDevices) {
  // Enable control buttons
}

// Check viewer-only
if (userInfo.isViewer) {
  // Disable control buttons
}

// Check basic user
if (userInfo.isBasicUser) {
  // Show "no devices" message
}
```

---

## 🔌 WebSocket

```dart
import 'package:web_socket_channel/web_socket_channel.dart';
import 'constants/api_config.dart';

final token = await authService.getToken();
final wsUrl = ApiConfig.deviceWebSocketUrl(deviceId, token!);
final channel = WebSocketChannel.connect(Uri.parse(wsUrl));

channel.stream.listen((message) {
  final data = jsonDecode(message);
  print('Temperature: ${data['latest']['temperature']}');
});
```

---

## 📍 Available Endpoints

### Authentication
```dart
ApiConfig.authFirebaseLoginUrl          // POST /api/auth/firebase/login
```

### User Management
```dart
ApiConfig.usersUrl                      // GET/PATCH/DELETE /api/users/me
ApiConfig.userRoleUrl(userId)           // PATCH /api/users/{user_id}/role
ApiConfig.fcmTokenUrl                   // POST/DELETE /api/users/me/fcm-token
```

### Device Management
```dart
ApiConfig.devicesUrl                    // GET /api/devices/
ApiConfig.unclaimedDevicesUrl           // GET /api/devices/unclaimed
ApiConfig.allDevicesUrl                 // GET /api/devices/all
ApiConfig.registerDeviceUrl             // POST /api/devices/register
ApiConfig.claimDeviceUrl                // POST /api/devices/claim
ApiConfig.deviceUpdateUrl(deviceId)     // PATCH /api/devices/{device_id}
ApiConfig.deviceDeleteUrl(deviceId)     // DELETE /api/devices/{device_id}
ApiConfig.deviceLogsUrl(deviceId)       // GET /api/devices/{device_id}/logs
ApiConfig.deviceControlUrl(deviceId)    // POST /api/devices/{device_id}/control
ApiConfig.deviceAlertsUrl(deviceId)     // GET /api/devices/{device_id}/alerts
ApiConfig.deviceStatsUrl(deviceId)      // GET /api/devices/{device_id}/stats/daily
ApiConfig.deviceUnclaimUrl(deviceId)    // POST /api/devices/{device_id}/unclaim
ApiConfig.deviceStatusUrl(deviceId)     // GET /api/devices/{device_id}/status
ApiConfig.deviceAssignUrl(deviceId)     // POST /api/devices/{device_id}/assign
ApiConfig.deviceUnassignUrl(deviceId, userId)  // DELETE /api/devices/{device_id}/assign/{user_id}
ApiConfig.deviceAssignmentsUrl(deviceId)       // GET /api/devices/{device_id}/assignments
```

### Admin Dashboard
```dart
ApiConfig.adminStatsUrl                 // GET /api/admin/stats
ApiConfig.adminUsersUrl                 // GET /api/admin/users
ApiConfig.adminSyncUsersUrl             // POST /api/admin/sync-firebase-users
ApiConfig.adminCleanupLogsUrl           // POST /api/admin/cleanup-logs
```

### Health Check
```dart
ApiConfig.healthUrl                     // GET /api/health
```

---

## 🎯 Component Control Values

```dart
// Valid component values for device control
'kipas'           // Fan
'lampu'           // Light
'pompa'           // Pump
'pakan_otomatis'  // Auto Feeder

// Example
await dio.post(
  ApiConfig.deviceControlUrl(deviceId),
  data: {
    'component': 'kipas',
    'state': true,  // true = ON, false = OFF
  },
);
```

---

## 📊 Pagination

```dart
// All paginated endpoints support these query parameters
final response = await dio.get(
  ApiConfig.devicesUrl,
  queryParameters: {
    'page': 1,      // Page number (default: 1)
    'limit': 20,    // Items per page (default: 20, max: 100)
  },
);

// Response structure
{
  "data": [...],
  "total": 50,
  "page": 1,
  "limit": 20,
  "total_pages": 3
}
```

---

## 🔍 Request ID Logging

```dart
// Request IDs are automatically logged by AuthInterceptor
// Access them in exceptions for debugging

try {
  await deviceService.getDevices();
} on ApiException catch (e) {
  print('Error: ${e.message}');
  print('Request ID: ${e.requestId}');  // For support tickets
}
```

---

## 🎨 UI Helpers

### Show error dialog
```dart
void showErrorDialog(BuildContext context, String title, String message) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}
```

### Show error snackbar
```dart
void showErrorSnackbar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
    ),
  );
}
```

### Show success snackbar
```dart
void showSuccessSnackbar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.green,
    ),
  );
}
```

---

## 🧪 Testing

### Mock AuthService
```dart
class MockAuthService extends AuthService {
  @override
  Future<LoginResponse> login(String firebaseIdToken) async {
    return LoginResponse(
      accessToken: 'mock_token',
      tokenType: 'bearer',
      userInfo: UserInfo(
        email: 'test@example.com',
        fullName: 'Test User',
        role: 'admin',
      ),
    );
  }
}
```

---

## 📝 Logging

All networking operations are automatically logged with these prefixes:

- `AuthInterceptor` — Request/response/error logs
- `TokenManager` — Token storage operations
- `AuthService` — Login/logout operations
- `DioClient` — HTTP request/response details

Search logs by name:
```dart
import 'dart:developer' as developer;

developer.log('Custom message', name: 'MyService');
```

---

**For complete documentation, see `NETWORKING_README.md`**
