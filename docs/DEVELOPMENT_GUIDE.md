# Development Guide

This guide reflects the current Flutter project state. It replaces the older migration, checklist, and implementation-summary documents.

## Active Architecture

The app uses a service-based networking layer:

- `ApiConfig.initialize()` loads `.env`, appends `/api`, and configures `DioClient`.
- `DioClient().dio` is the only HTTP client expected for backend calls.
- `AuthInterceptor` injects JWT Bearer tokens, maps error responses to `ApiException` subclasses, triggers logout on auth failures, and opens the maintenance screen on 503.
- `TokenManager` stores the JWT, user id/email/role, detects secure-storage corruption, and exposes `onLogout`.
- `AuthService` handles Firebase ID token exchange, logout, auth checks, and current-user lookup.
- `DeviceService` handles device list, claim, control, sensor logs, assignments, and admin-user lookup by email.
- `DeviceProvider` stores relay toggle state in memory and performs optimistic control updates with rollback.

## Startup Flow

1. `main.dart` initializes Firebase.
2. `ApiConfig.initialize()` configures the API base URL.
3. `TokenManager.detectAndClearCorruption()` handles broken secure storage.
4. If a stored JWT exists, the app starts at `HomeScreen`; otherwise it starts at `LoginPage`.
5. `MyApp` subscribes to `TokenManager().onLogout` and navigates to `AppRoutes.login` on logout events.

## Auth Flow

Login uses Firebase first, then exchanges the Firebase ID token through:

```dart
final loginResponse = await AuthService().login(firebaseIdToken);
```

`AuthService.login()` validates the token length, posts to `ApiConfig.authFirebaseLoginUrl`, parses `LoginResponse`, and stores JWT/user info through `TokenManager`.

Manual logout should clear both Firebase and local backend auth where applicable. Global logout navigation is centralized in `main.dart`; do not duplicate navigation logic in every service.

## Device Flows

Device list:

```dart
final response = await DeviceService().getDevices(page: 1, limit: 20);
```

Device control:

```dart
await DeviceService().controlDevice(
  deviceId: device.id,
  component: DeviceComponent.lampu,
  state: true,
);
```

Claim by QR/MAC:

```dart
final device = await DeviceService().claimDevice(
  macAddress: scannedMac,
  name: 'Kandang Utara',
);
```

Sensor logs:

```dart
final logs = await DeviceService().getDeviceLogs(
  deviceId: device.id,
  page: 1,
  limit: 50,
);
```

Assignments:

```dart
final user = await DeviceService().findUserByEmail(email);
await DeviceService().assignUserToDevice(
  deviceId: device.id,
  userId: user.id!,
  role: 'operator',
);
```

Use `role: 'operator'` or `role: 'viewer'` for assignments.

## UI Pages

| File | Current purpose |
| --- | --- |
| `lib/pages/login_page.dart` | Firebase login and backend JWT exchange |
| `lib/pages/register_page.dart` | Registration UI |
| `lib/pages/home_screen.dart` | Authenticated tab shell, user greeting, first-device status, alert bottom sheet |
| `lib/pages/device_list_page.dart` | Main dashboard with paginated devices and QR shortcut |
| `lib/pages/device_detail_page.dart` | Latest sensor cards, light indicator, Lite relay controls, access-management shortcut |
| `lib/pages/device_assignment_page.dart` | Owner access management for operator/viewer assignments |
| `lib/pages/devices_page.dart` | BLE WiFi provisioning for ESP32 |
| `lib/pages/scan_page.dart` | QR/manual MAC claim flow |
| `lib/pages/history_page.dart` | Recent logs and alerts for the first accessible device |
| `lib/pages/profile_page.dart` | Profile, logout, account actions |

## Error Handling

Catch `ApiException` subclasses in UI code and show user feedback through `ErrorHandler`.

Important exception types:

- `UnauthorizedException`: auth failure; interceptor triggers logout.
- `ForbiddenException`: permission denied; show the backend message.
- `ValidationException`: show field-level validation messages.
- `NotFoundException`: resource not found or no access.
- `RateLimitException`: show wait/retry guidance.
- `NetworkException`: show retry UI.
- `ServerException`: backend/MQTT failure.
- `ServiceUnavailableException`: maintenance/unavailable state.

## Current Limitations

- WebSocket streaming is documented by the backend contract but not wired into the UI yet.
- `DeviceProvider` keeps relay state in memory. The backend device response does not currently expose per-component ON/OFF state, so app restart resets toggles to default until the user acts again.
- Hardware Lite exposes only `lampu` and `pompa` toggles. `kipas`, `pakan_otomatis`, and `exhaust_fan` are implemented in the enum/API contract but hidden in `DeviceDetailPage`.
- `HistoryPage` reads the first accessible device rather than letting the user select a device.
- `DeviceService.findUserByEmail()` scans paginated admin users client-side because there is no dedicated search-by-email endpoint.

## Commands

```bash
flutter pub get
flutter run
flutter analyze
flutter test
dart format lib test
flutter build apk --release
```

## Documentation Map

- `README.md`: product overview, project structure, commands, active app status.
- `docs/API_CONTRACT.md`: backend API source of truth.
- `docs/DEVELOPMENT_GUIDE.md`: current frontend implementation guide.
- `AGENTS.md`: contributor and coding-agent guide.
