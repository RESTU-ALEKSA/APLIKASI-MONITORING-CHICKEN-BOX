# ✅ Implementation Checklist

Use this checklist to track your integration progress.

---

## 📦 Phase 1: Setup (5 minutes)

- [ ] Run `flutter pub get` to install `dio` package
- [ ] Verify all files are created:
  - [ ] `lib/core/network/dio_client.dart`
  - [ ] `lib/core/network/auth_interceptor.dart`
  - [ ] `lib/core/network/token_manager.dart`
  - [ ] `lib/core/network/api_exception.dart`
  - [ ] `lib/models/auth/login_request.dart`
  - [ ] `lib/models/auth/login_response.dart`
  - [ ] `lib/models/auth/user_info.dart`
  - [ ] `lib/services/auth_service.dart`
  - [ ] `lib/constants/api_config.dart` (updated)
- [ ] Read `NETWORKING_README.md` (15 min)
- [ ] Read `MIGRATION_GUIDE.md` (10 min)

---

## 🔧 Phase 2: Core Integration (30 minutes)

### Step 1: Update main.dart
- [ ] Import `ApiConfig`
- [ ] Add `await ApiConfig.initialize()` before `runApp()`
- [ ] Test: App starts without errors

### Step 2: Add Global Logout Listener
- [ ] Import `AuthService` in root widget
- [ ] Create `AuthService` instance
- [ ] Add `authService.onLogout.listen()` in `initState()`
- [ ] Implement navigation to login screen
- [ ] Test: Listener is registered (check logs)

### Step 3: Update Login Page
- [ ] Import `AuthService` and exception classes
- [ ] Replace HTTP calls with `authService.login()`
- [ ] Add try-catch for all exception types:
  - [ ] `ValidationException`
  - [ ] `UnauthorizedException`
  - [ ] `ForbiddenException`
  - [ ] `RateLimitException`
  - [ ] `NetworkException`
- [ ] Remove manual token storage code
- [ ] Test: Login with valid credentials
- [ ] Test: Login with expired Firebase token (401)
- [ ] Test: Login with deactivated account (403)
- [ ] Test: Login with rate limit (429)

### Step 4: Update Logout Functionality
- [ ] Import `AuthService`
- [ ] Replace manual token deletion with `authService.logout()`
- [ ] Keep Firebase sign-out
- [ ] Test: Logout clears token
- [ ] Test: Can't access protected endpoints after logout

---

## 🚀 Phase 3: Service Layer (1-2 hours)

### Create DeviceService
- [ ] Create `lib/services/device_service.dart`
- [ ] Import `DioClient`, `ApiConfig`, exceptions
- [ ] Implement `getDevices()` method
- [ ] Implement `controlDevice()` method
- [ ] Implement `claimDevice()` method
- [ ] Add error handling for all methods
- [ ] Test: Get devices list
- [ ] Test: Control device (kipas, lampu, etc.)
- [ ] Test: Claim device via QR code

### Create UserService (Optional)
- [ ] Create `lib/services/user_service.dart`
- [ ] Implement `getProfile()` method
- [ ] Implement `updateProfile()` method
- [ ] Implement `deleteAccount()` method
- [ ] Test: Get user profile
- [ ] Test: Update display name
- [ ] Test: Delete account

---

## 🎨 Phase 4: UI Updates (2-3 hours)

### Update Devices Page
- [ ] Import `DeviceService` and exceptions
- [ ] Replace HTTP calls with `deviceService.getDevices()`
- [ ] Add error handling UI (dialogs/snackbars)
- [ ] Remove manual Authorization headers
- [ ] Test: Load devices list
- [ ] Test: Handle 401 error (auto-logout)
- [ ] Test: Handle 403 error (permission denied)
- [ ] Test: Handle network error

### Update Device Control UI
- [ ] Import `DeviceService` and exceptions
- [ ] Replace HTTP calls with `deviceService.controlDevice()`
- [ ] Add error handling for control actions
- [ ] Test: Turn on/off kipas
- [ ] Test: Turn on/off lampu
- [ ] Test: Turn on/off pompa
- [ ] Test: Turn on/off pakan_otomatis
- [ ] Test: Handle 403 error (viewer role)

### Update Scan Page
- [ ] Import `DeviceService` and exceptions
- [ ] Replace HTTP calls with `deviceService.claimDevice()`
- [ ] Add error handling for claim action
- [ ] Test: Scan QR code
- [ ] Test: Claim unclaimed device
- [ ] Test: Handle 400 error (already claimed)
- [ ] Test: Handle 403 error (not admin)
- [ ] Test: Handle 404 error (MAC not registered)

### Update Profile Page
- [ ] Import `UserService` and exceptions
- [ ] Replace HTTP calls with `userService` methods
- [ ] Add error handling
- [ ] Test: View profile
- [ ] Test: Update display name
- [ ] Test: Delete account

---

## 🧹 Phase 5: Cleanup (30 minutes)

### Remove Old Code
- [ ] Remove `import 'package:http/http.dart' as http;`
- [ ] Remove manual token storage code
- [ ] Remove manual Authorization header code
- [ ] Remove manual error parsing code
- [ ] Remove old API URL constants (if any)

### Code Review
- [ ] All API calls use services
- [ ] All services use `DioClient().dio`
- [ ] All services handle exceptions
- [ ] No manual token management
- [ ] No manual header injection
- [ ] Logout listener is registered

---

## 🧪 Phase 6: Testing (1-2 hours)

### Authentication Tests
- [ ] Login with valid Firebase token → Success
- [ ] Login with expired Firebase token → 401 error shown
- [ ] Login with deactivated account → 403 error shown
- [ ] Login with rate limit exceeded → 429 error shown
- [ ] Logout → Token cleared, redirected to login
- [ ] Auto-logout on 401 → Redirected to login
- [ ] Auto-logout on 403 → Redirected to login

### Device Management Tests
- [ ] Get devices list → Success
- [ ] Get devices with no permission → 403 error
- [ ] Control device (operator/admin) → Success
- [ ] Control device (viewer) → 403 error
- [ ] Claim device (admin) → Success
- [ ] Claim device (user) → 403 error
- [ ] Claim already claimed device → 400 error

### Network Error Tests
- [ ] Turn off WiFi → Network error shown
- [ ] Turn on WiFi → Retry works
- [ ] Timeout → Network error shown

### Edge Cases
- [ ] Token expires during session → Auto-logout
- [ ] Account deactivated during session → Auto-logout
- [ ] Rate limit exceeded → "Please wait" message
- [ ] Server error (500) → Generic error shown
- [ ] Server maintenance (503) → Maintenance message

---

## 📊 Phase 7: Monitoring (Ongoing)

### Logging
- [ ] Check logs for `AuthInterceptor` messages
- [ ] Check logs for `TokenManager` messages
- [ ] Check logs for `AuthService` messages
- [ ] Check logs for Request-ID headers
- [ ] Verify no sensitive data in logs

### Performance
- [ ] API calls complete in reasonable time
- [ ] No memory leaks (token manager)
- [ ] No excessive token reads/writes
- [ ] Logout stream doesn't cause issues

---

## 🎓 Phase 8: Documentation (Optional)

### Team Documentation
- [ ] Share `NETWORKING_README.md` with team
- [ ] Share `MIGRATION_GUIDE.md` with team
- [ ] Share `QUICK_REFERENCE.md` with team
- [ ] Document any custom services created
- [ ] Document any custom error handling patterns

### Code Comments
- [ ] Add comments to complex error handling
- [ ] Add comments to custom services
- [ ] Add comments to UI error handling

---

## 🚀 Phase 9: Deployment

### Pre-Deployment Checklist
- [ ] All tests passing
- [ ] No console errors
- [ ] No memory leaks
- [ ] Token storage working
- [ ] Logout working
- [ ] Error handling working
- [ ] Rate limiting respected

### Production Checklist
- [ ] `.env` file has production BASE_URL
- [ ] Firebase project is production project
- [ ] Backend API is production API
- [ ] All error messages are user-friendly
- [ ] All logs are appropriate for production

---

## 📞 Support

### If You Get Stuck

1. **Check Documentation**
   - `NETWORKING_README.md` — Complete documentation
   - `MIGRATION_GUIDE.md` — Step-by-step migration
   - `QUICK_REFERENCE.md` — Common operations
   - `API_CONTRACT.md` — Backend API specs

2. **Check Examples**
   - `lib/examples/login_example.dart` — Complete examples

3. **Check Logs**
   - Search for `AuthInterceptor`, `TokenManager`, `AuthService`
   - Look for Request-ID headers
   - Check for error messages

4. **Common Issues**
   - "No token available" → Call `ApiConfig.initialize()` in main.dart
   - 401 on all requests → Check token storage
   - Logout not working → Check listener registration
   - Base URL wrong → Check `.env` file

---

## ✅ Completion Criteria

You're done when:

- [ ] All API calls use the new networking layer
- [ ] All error types are handled
- [ ] Automatic logout works on 401/403
- [ ] Token management is automatic
- [ ] All tests pass
- [ ] No old HTTP code remains
- [ ] Documentation is updated (if needed)

---

**Estimated Total Time: 5-8 hours**

**Good luck! 🚀**
