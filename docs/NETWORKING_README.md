# Flutter Networking Infrastructure — Smart Chicken Box

Production-ready networking layer for the Smart Chicken Box IoT project, built according to `API_CONTRACT.md`.

## 📁 Architecture Overview

```
lib/
├── core/
│   └── network/
│       ├── dio_client.dart          # Singleton Dio instance with interceptors
│       ├── auth_interceptor.dart    # JWT injection + global error handling
│       ├── token_manager.dart       # Secure token storage + logout events
│       └── api_exception.dart       # Custom exception classes (401, 403, 422, 429, etc.)
├── constants/
│   └── api_config.dart              # Centralized endpoint definitions with /api prefix
├── models/
│   └── auth/
│       ├── login_request.dart       # Firebase login request (max 4096 chars)
│       ├── login_response.dart      # JWT + user_info response
│       └── user_info.dart           # User profile model with role helpers
├── services/
│   └── auth_service.dart            # Authentication API calls
└── examples/
    └── login_example.dart           # Complete usage examples
```

---

## 🚀 Quick Start

### 1. Initialize in `main.dart`

```dart
import 'package:firebase_core/firebase_core.dart';
import 'constants/api_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  // Initialize ApiConfig (loads .env and configures DioClient)
  await ApiConfig.initialize();
  
  runApp(const MyApp());
}
```

### 2. Listen to Global Logout Events

In your root widget or main screen:

```dart
import 'services/auth_service.dart';

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    
    // Listen to logout events (triggered by 401/403 errors)
    _authService.onLogout.listen((_) {
      // Navigate to login screen
      Navigator.of(context).pushReplacementNamed('/login');
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Your app configuration
    );
  }
}
```

### 3. Implement Login

```dart
import 'package:firebase_auth/firebase_auth.dart';
import 'services/auth_service.dart';
import 'core/network/api_exception.dart';

final AuthService _authService = AuthService();
final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

Future<void> _handleLogin() async {
  try {
    // Step 1: Sign in with Firebase
    final GoogleAuthProvider googleProvider = GoogleAuthProvider();
    final UserCredential userCredential = 
        await _firebaseAuth.signInWithProvider(googleProvider);

    // Step 2: Get Firebase ID token
    final String? idToken = await userCredential.user?.getIdToken();
    
    if (idToken == null) {
      throw Exception('Gagal mendapatkan token Firebase');
    }

    // Step 3: Exchange Firebase token for backend JWT
    final loginResponse = await _authService.login(idToken);

    // Step 4: Navigate to home screen
    Navigator.pushReplacementNamed(context, '/home');
    
    print('Logged in as: ${loginResponse.userInfo.email}');
    print('Role: ${loginResponse.userInfo.role}');
  } on ValidationException catch (e) {
    // 422 - Token too long or invalid format
    showError('Validasi Gagal', e.allMessages);
  } on UnauthorizedException catch (e) {
    // 401 - Invalid or expired Firebase token
    showError('Token Tidak Valid', e.message);
  } on ForbiddenException catch (e) {
    // 403 - Account deactivated
    showError('Akses Ditolak', e.message);
  } on RateLimitException catch (e) {
    // 429 - Too many login attempts
    showError('Terlalu Banyak Percobaan', e.message);
  } on NetworkException catch (e) {
    // Network error
    showError('Kesalahan Jaringan', e.message);
  }
}
```

---

## 🔐 Authentication Flow

```
┌─────────────┐
│   Flutter   │
│     App     │
└──────┬──────┘
       │
       │ 1. Sign in with Google
       ▼
┌─────────────┐
│  Firebase   │
│    Auth     │
└──────┬──────┘
       │
       │ 2. Get ID token
       ▼
┌─────────────┐
│ AuthService │
│   .login()  │
└──────┬──────┘
       │
       │ 3. POST /api/auth/firebase/login
       ▼
┌─────────────┐
│   Backend   │
│   FastAPI   │
└──────┬──────┘
       │
       │ 4. Return JWT + user_info
       ▼
┌─────────────┐
│TokenManager │
│ (Secure     │
│  Storage)   │
└─────────────┘
```

---

## 🛡️ Error Handling

All API errors are automatically converted to typed exceptions by `AuthInterceptor`:

| HTTP Code | Exception Class | Client Action |
|:---------:|----------------|---------------|
| **400** | `BadRequestException` | Show error message to user |
| **401** | `UnauthorizedException` | **Auto-logout + redirect to login** |
| **403** | `ForbiddenException` | Show error message, do NOT retry |
| **404** | `NotFoundException` | Show "not found" message |
| **422** | `ValidationException` | Parse field errors, highlight in UI |
| **429** | `RateLimitException` | Show "please wait" message |
| **500** | `ServerException` | Show generic error, retry once |
| **503** | `ServiceUnavailableException` | Show "maintenance" message |
| Network | `NetworkException` | Show "no internet" message |

### Example: Handling Validation Errors (422)

```dart
try {
  await authService.login(idToken);
} on ValidationException catch (e) {
  // Get all error messages
  print(e.allMessages);
  
  // Get errors for specific field
  final tokenErrors = e.getFieldErrors('id_token');
  for (var error in tokenErrors) {
    print('${error.field}: ${error.msg}');
  }
}
```

---

## 🔄 Automatic Token Injection

`AuthInterceptor` automatically injects the JWT Bearer token into all requests (except `/auth/firebase/login` and `/health`):

```dart
// You don't need to manually add Authorization header
final response = await DioClient().dio.get('/devices/');

// AuthInterceptor automatically adds:
// Authorization: Bearer eyJhbGciOiJIUzI1NiIs...
```

---

## 📡 Making API Calls

### Example: Device Service

```dart
import 'package:dio/dio.dart';
import '../core/network/dio_client.dart';
import '../core/network/api_exception.dart';
import '../constants/api_config.dart';

class DeviceService {
  final Dio _dio = DioClient().dio;
  
  /// Get list of devices
  /// Endpoint: GET /api/devices/
  Future<List<Device>> getDevices({int page = 1, int limit = 20}) async {
    try {
      final response = await _dio.get(
        ApiConfig.devicesUrl,
        queryParameters: {'page': page, 'limit': limit},
      );
      
      if (response.statusCode == 200) {
        final data = response.data['data'] as List;
        return data.map((json) => Device.fromJson(json)).toList();
      }
      
      throw UnknownException('Unexpected status: ${response.statusCode}');
    } on DioException catch (e) {
      if (e.error is ApiException) {
        throw e.error as ApiException;
      }
      throw NetworkException('Network error: ${e.message}');
    }
  }
  
  /// Control device component
  /// Endpoint: POST /api/devices/{device_id}/control
  Future<void> controlDevice({
    required String deviceId,
    required String component,
    required bool state,
  }) async {
    try {
      final response = await _dio.post(
        ApiConfig.deviceControlUrl(deviceId),
        data: {
          'component': component,
          'state': state,
        },
      );
      
      if (response.statusCode != 200) {
        throw UnknownException('Control failed: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.error is ApiException) {
        throw e.error as ApiException;
      }
      throw NetworkException('Network error: ${e.message}');
    }
  }
}
```

---

## 🎯 Role-Based Access Control

The `UserInfo` model includes helper methods for role checking:

```dart
final userInfo = loginResponse.userInfo;

// Check admin privileges
if (userInfo.isAdmin) {
  // Show admin panel
}

if (userInfo.isSuperAdmin) {
  // Show super admin features
}

// Check device control permissions
if (userInfo.canControlDevices) {
  // Enable control buttons
}

// Check viewer-only access
if (userInfo.isViewer) {
  // Disable control buttons, show read-only UI
}

// Check basic user (no device access)
if (userInfo.isBasicUser) {
  // Show "no devices" message
}
```

---

## 📝 Request ID Logging

All responses include an `X-Request-ID` header for debugging. The `AuthInterceptor` automatically logs it:

```
← Response [200] Request-ID: a1b2c3d4-e5f6-7890-abcd-ef1234567890
```

You can also access it in exceptions:

```dart
try {
  await deviceService.getDevices();
} on ApiException catch (e) {
  print('Error: ${e.message}');
  print('Request ID: ${e.requestId}'); // For support tickets
}
```

---

## 🔌 WebSocket Support

For real-time sensor data streaming:

```dart
import 'package:web_socket_channel/web_socket_channel.dart';
import '../constants/api_config.dart';
import '../services/auth_service.dart';

final authService = AuthService();
final token = await authService.getToken();

if (token != null) {
  final wsUrl = ApiConfig.deviceWebSocketUrl(deviceId, token);
  final channel = WebSocketChannel.connect(Uri.parse(wsUrl));
  
  channel.stream.listen((message) {
    final data = jsonDecode(message);
    print('Temperature: ${data['latest']['temperature']}');
  });
}
```

---

## 🧪 Testing

### Mock AuthService for Testing

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

## 📚 API Contract Reference

All endpoints, error codes, and validation rules are documented in `API_CONTRACT.md`. This networking layer is built to match that contract exactly.

Key sections:
- **Section 1**: Base URL and authentication method
- **Section 2**: HTTP error dictionary (401, 403, 422, 429, etc.)
- **Section 3**: REST API endpoints
- **Section 4**: WebSocket specifications

---

## 🔧 Configuration

### Environment Variables (.env)

```env
BASE_URL=https://api.pcb.my.id
```

The `ApiConfig.initialize()` method automatically:
1. Loads the `.env` file
2. Appends `/api` to the base URL
3. Configures `DioClient` with the full API base URL

---

## 🚨 Important Notes

1. **Token Validation**: Firebase ID tokens are validated client-side (max 4096 chars) before sending to prevent 422 errors.

2. **Automatic Logout**: When 401 or 403 errors occur, `AuthInterceptor` automatically:
   - Clears the stored JWT token
   - Triggers a logout event via `TokenManager.onLogout` stream
   - Your app should listen to this stream and navigate to login

3. **Rate Limiting**: 429 errors throw `RateLimitException` with message "Terlalu banyak permintaan. Silakan tunggu sebentar." Do NOT auto-retry to avoid spamming the server.

4. **Error Messages**: All error messages from the backend are in Indonesian. Display them directly to users.

5. **Secure Storage**: JWT tokens are stored using `flutter_secure_storage` with encrypted shared preferences on Android.

---

## 📦 Dependencies

```yaml
dependencies:
  dio: ^5.4.0
  flutter_secure_storage: ^9.0.0
  flutter_dotenv: ^6.0.0
  firebase_auth: ^6.2.0
```

---

## 🎓 Next Steps

1. **Integrate with existing login page**: Replace your current HTTP calls with `AuthService.login()`
2. **Create device service**: Follow the pattern in `examples/login_example.dart`
3. **Implement logout listener**: Add `authService.onLogout.listen()` in your root widget
4. **Add error handling UI**: Create reusable error dialogs/snackbars for each exception type
5. **Test with real backend**: Verify all error codes match the contract

---

## 📞 Support

For questions about the API contract, refer to `API_CONTRACT.md`.

For networking infrastructure issues, check:
- `lib/core/network/` — Core networking classes
- `lib/examples/login_example.dart` — Complete usage examples
- Developer logs (search for `AuthInterceptor`, `TokenManager`, `AuthService`)

---

**Built with ❤️ for Smart Chicken Box IoT Project**
