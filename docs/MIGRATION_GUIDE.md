# Migration Guide — Integrating New Networking Infrastructure

This guide helps you integrate the new Dio-based networking layer with your existing Flutter app.

---

## 📋 Pre-Migration Checklist

- [x] `dio: ^5.4.0` added to `pubspec.yaml`
- [x] Core networking files created in `lib/core/network/`
- [x] Auth models created in `lib/models/auth/`
- [x] `AuthService` created in `lib/services/`
- [x] `ApiConfig` updated with `/api` prefix

---

## 🔄 Step-by-Step Migration

### Step 1: Update `main.dart`

**Before:**
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}
```

**After:**
```dart
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

---

### Step 2: Add Global Logout Listener

In your root widget (e.g., `MyApp` or `HomeScreen`):

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
      // Use your navigation method (Navigator, GoRouter, etc.)
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/login',
        (route) => false,
      );
      
      // Show logout message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sesi Anda telah berakhir. Silakan login kembali.'),
          backgroundColor: Colors.red,
        ),
      );
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

---

### Step 3: Update Login Page

**File:** `lib/pages/login_page.dart`

**Before (using HTTP package):**
```dart
import 'package:http/http.dart' as http;

Future<void> _handleLogin() async {
  // Get Firebase token
  final idToken = await user?.getIdToken();
  
  // Make HTTP request
  final response = await http.post(
    Uri.parse('${ApiConfig.baseUrl}/auth/firebase/login'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'id_token': idToken}),
  );
  
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    // Store token manually
    await storage.write(key: 'token', value: data['access_token']);
    Navigator.pushReplacementNamed(context, '/home');
  } else {
    // Handle error
    showError('Login failed');
  }
}
```

**After (using AuthService):**
```dart
import 'services/auth_service.dart';
import 'core/network/api_exception.dart';

final AuthService _authService = AuthService();

Future<void> _handleLogin() async {
  try {
    // Get Firebase token
    final idToken = await user?.getIdToken();
    
    if (idToken == null) {
      throw Exception('Gagal mendapatkan token Firebase');
    }
    
    // Call AuthService (automatically stores token)
    final loginResponse = await _authService.login(idToken);
    
    // Navigate to home
    Navigator.pushReplacementNamed(context, '/home');
    
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Selamat datang, ${loginResponse.userInfo.fullName}!'),
        backgroundColor: Colors.green,
      ),
    );
  } on ValidationException catch (e) {
    // 422 - Token validation error
    _showError('Validasi Gagal', e.allMessages);
  } on UnauthorizedException catch (e) {
    // 401 - Invalid Firebase token
    _showError('Token Tidak Valid', e.message);
  } on ForbiddenException catch (e) {
    // 403 - Account deactivated
    _showError('Akses Ditolak', e.message);
  } on RateLimitException catch (e) {
    // 429 - Too many attempts
    _showError('Terlalu Banyak Percobaan', e.message);
  } on NetworkException catch (e) {
    // Network error
    _showError('Kesalahan Jaringan', e.message);
  } catch (e) {
    _showError('Kesalahan', 'Terjadi kesalahan: $e');
  }
}

void _showError(String title, String message) {
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

---

### Step 4: Update Logout Functionality

**Before:**
```dart
Future<void> _handleLogout() async {
  await FirebaseAuth.instance.signOut();
  await storage.delete(key: 'token');
  Navigator.pushReplacementNamed(context, '/login');
}
```

**After:**
```dart
import 'services/auth_service.dart';

final AuthService _authService = AuthService();

Future<void> _handleLogout() async {
  // Sign out from Firebase
  await FirebaseAuth.instance.signOut();
  
  // Clear backend JWT token
  await _authService.logout();
  
  // Navigate to login
  Navigator.pushReplacementNamed(context, '/login');
}
```

---

### Step 5: Create Device Service (Example)

**File:** `lib/services/device_service.dart`

```dart
import 'package:dio/dio.dart';
import '../core/network/dio_client.dart';
import '../core/network/api_exception.dart';
import '../constants/api_config.dart';
import '../models/device.dart'; // Your existing device model

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
  
  /// Claim device
  /// Endpoint: POST /api/devices/claim
  Future<Device> claimDevice({
    required String macAddress,
    required String name,
  }) async {
    try {
      final response = await _dio.post(
        ApiConfig.claimDeviceUrl,
        data: {
          'mac_address': macAddress,
          'name': name,
        },
      );
      
      if (response.statusCode == 200) {
        return Device.fromJson(response.data);
      }
      
      throw UnknownException('Claim failed: ${response.statusCode}');
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

### Step 6: Update UI Pages to Use New Services

**Example: Devices Page**

**Before:**
```dart
import 'package:http/http.dart' as http;

Future<void> _loadDevices() async {
  final token = await storage.read(key: 'token');
  final response = await http.get(
    Uri.parse('${ApiConfig.baseUrl}/devices/'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
  );
  
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    setState(() {
      _devices = (data['data'] as List)
          .map((json) => Device.fromJson(json))
          .toList();
    });
  }
}
```

**After:**
```dart
import '../services/device_service.dart';
import '../core/network/api_exception.dart';

final DeviceService _deviceService = DeviceService();

Future<void> _loadDevices() async {
  try {
    final devices = await _deviceService.getDevices();
    setState(() => _devices = devices);
  } on UnauthorizedException catch (e) {
    // User will be automatically logged out by AuthInterceptor
    // Just show a message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.message)),
    );
  } on ForbiddenException catch (e) {
    // User doesn't have permission
    _showErrorDialog('Akses Ditolak', e.message);
  } on RateLimitException catch (e) {
    // Rate limit exceeded
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(e.message),
        duration: const Duration(seconds: 5),
      ),
    );
  } on NetworkException catch (e) {
    // Network error - show retry option
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(e.message),
        action: SnackBarAction(
          label: 'Retry',
          onPressed: () => _loadDevices(),
        ),
      ),
    );
  } catch (e) {
    _showErrorDialog('Kesalahan', 'Terjadi kesalahan: $e');
  }
}
```

---

### Step 7: Update Scan Page (QR Code Claim)

**File:** `lib/pages/scan_page.dart`

**After scanning QR code:**
```dart
import '../services/device_service.dart';
import '../core/network/api_exception.dart';

final DeviceService _deviceService = DeviceService();

Future<void> _handleQRCodeScanned(String macAddress) async {
  // Show name input dialog
  final name = await _showNameInputDialog();
  
  if (name == null || name.isEmpty) return;
  
  try {
    final device = await _deviceService.claimDevice(
      macAddress: macAddress,
      name: name,
    );
    
    // Show success
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Device ${device.name} berhasil diklaim!'),
        backgroundColor: Colors.green,
      ),
    );
    
    // Navigate back to devices page
    Navigator.pop(context);
  } on BadRequestException catch (e) {
    // Device already claimed or invalid MAC
    _showErrorDialog('Gagal Klaim Device', e.message);
  } on ForbiddenException catch (e) {
    // User doesn't have admin role
    _showErrorDialog('Akses Ditolak', e.message);
  } on NotFoundException catch (e) {
    // MAC address not registered
    _showErrorDialog('Device Tidak Ditemukan', e.message);
  } on NetworkException catch (e) {
    _showErrorDialog('Kesalahan Jaringan', e.message);
  }
}
```

---

## 🧹 Cleanup Tasks

After migration, you can remove:

1. **Old HTTP imports:**
   ```dart
   // Remove these
   import 'package:http/http.dart' as http;
   ```

2. **Manual token storage code:**
   ```dart
   // Remove manual token reads/writes
   await storage.write(key: 'token', value: token);
   final token = await storage.read(key: 'token');
   ```

3. **Manual Authorization headers:**
   ```dart
   // Remove manual header injection
   headers: {'Authorization': 'Bearer $token'}
   ```

4. **Manual error parsing:**
   ```dart
   // Remove manual JSON error parsing
   if (response.statusCode == 401) {
     // Handle 401
   }
   ```

---

## ✅ Testing Checklist

After migration, test these scenarios:

- [ ] Login with valid Firebase token
- [ ] Login with expired Firebase token (should show 401 error)
- [ ] Login with deactivated account (should show 403 error)
- [ ] Login with rate limit exceeded (should show 429 error)
- [ ] Automatic logout on 401 error (e.g., expired JWT)
- [ ] Automatic logout on 403 error (e.g., account deactivated)
- [ ] Network error handling (turn off WiFi)
- [ ] Device list loading
- [ ] Device control (kipas, lampu, pompa, pakan_otomatis)
- [ ] QR code scanning and device claiming
- [ ] Logout functionality

---

## 🐛 Troubleshooting

### Issue: "No token available" in logs

**Solution:** Make sure you call `await ApiConfig.initialize()` in `main.dart` before running the app.

### Issue: 401 errors on all requests

**Solution:** Check if the JWT token is being stored correctly after login. Add debug logs:
```dart
final token = await _authService.getToken();
print('Current token: $token');
```

### Issue: Base URL is wrong

**Solution:** Check your `.env` file. Make sure `BASE_URL` is set correctly:
```env
BASE_URL=https://api.pcb.my.id
```

### Issue: Logout listener not working

**Solution:** Make sure you're listening to `authService.onLogout` in a widget that stays alive (e.g., root widget, not a page that gets disposed).

---

## 📞 Need Help?

- Check `NETWORKING_README.md` for detailed documentation
- Check `lib/examples/login_example.dart` for complete examples
- Check `API_CONTRACT.md` for backend API specifications
- Check developer logs (search for `AuthInterceptor`, `TokenManager`, `AuthService`)

---

**Happy Coding! 🚀**
