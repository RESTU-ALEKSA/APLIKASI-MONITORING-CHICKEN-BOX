# 🚀 Quick Start Guide

Get up and running in 10 minutes.

---

## Step 1: Install Dependencies (2 minutes)

```bash
flutter pub get
```

This installs the `dio` package and updates dependencies.

---

## Step 2: Update main.dart (3 minutes)

**Add this import:**
```dart
import 'constants/api_config.dart';
```

**Update your main function:**
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  // Initialize ApiConfig (NEW - loads .env and configures DioClient)
  await ApiConfig.initialize();
  
  runApp(const MyApp());
}
```

---

## Step 3: Add Logout Listener (5 minutes)

**In your root widget (MyApp or HomeScreen):**

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
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/login',
        (route) => false,
      );
      
      // Show message
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

## Step 4: Test It! (2 minutes)

Run your app:

```bash
flutter run
```

Check the console for these logs:
```
✓ DioClient initialized
✓ Base URL set to: https://api.pcb.my.id/api
```

If you see these, you're good to go! 🎉

---

## Next Steps

Now you're ready to integrate the networking layer with your existing pages.

**Choose your path:**

### Path A: Quick Integration (Recommended)
Follow the **MIGRATION_GUIDE.md** step-by-step to update your existing pages.

### Path B: Learn First
Read the **NETWORKING_README.md** to understand the architecture, then follow the migration guide.

### Path C: Jump In
Check **QUICK_REFERENCE.md** for common operations and start coding!

---

## Common Issues

### Issue: "No token available" in logs
**Solution:** Make sure you called `await ApiConfig.initialize()` in `main.dart` before `runApp()`.

### Issue: App crashes on startup
**Solution:** Check that your `.env` file exists and has `BASE_URL` set.

### Issue: Logout listener not working
**Solution:** Make sure you're listening in a widget that stays alive (root widget, not a page that gets disposed).

---

## What's Next?

1. **Update Login Page** — Replace HTTP calls with `AuthService.login()`
2. **Create Device Service** — Follow the pattern in `lib/examples/login_example.dart`
3. **Update UI Pages** — Replace HTTP calls with service methods
4. **Test Everything** — Use the checklist in `IMPLEMENTATION_CHECKLIST.md`

---

## Need Help?

- **Architecture Questions** → See `NETWORKING_README.md`
- **Migration Help** → See `MIGRATION_GUIDE.md`
- **Quick Reference** → See `QUICK_REFERENCE.md`
- **Code Examples** → See `lib/examples/login_example.dart`

---

**You're all set! Happy coding! 🚀**
