import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:developer' as developer;
import 'package:dio/dio.dart';
import '../constants/api_config.dart';
import '../core/network/dio_client.dart';
import '../core/network/token_manager.dart';
import '../services/auth_service.dart';

import '../constants/floating_navbar.dart';
import '../constants/app_colors.dart';
<<<<<<< HEAD
import 'device_list_page.dart';
=======
import 'home_page.dart';
>>>>>>> upstream/main
import 'devices_page.dart';
import 'scan_page.dart';
import 'history_page.dart';
import 'profile_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
<<<<<<< HEAD

  // --- CORE SERVICES ---
  final Dio _dio = DioClient().dio;
  final AuthService _authService = AuthService();
  Timer? _statusTimer;
=======
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  Timer? _pollingTimer;

  // --- STATE PERANGKAT & SENSOR ---
>>>>>>> upstream/main
  String? _activeDeviceId;
  bool _isDeviceOnline = false;
  bool _isCheckingStatus = true;
  String _temp = '--', _humi = '--', _amo = '--';
  bool _isSensorLoading = true;

  // --- STATE USER & NOTIF ---
  String _greeting = 'Halo';
  String _userName = 'Memuat...';
  String _pictureUrl = '';
<<<<<<< HEAD

  // --- VARIABEL NOTIFIKASI ---
=======
>>>>>>> upstream/main
  List<dynamic> _notifications = [];
  int _notificationCount = 0;

  // --- DATA KONTROL ---
  final List<Map<String, dynamic>> _controlItems = [
    {'icon': Icons.water_drop_rounded, 'title': 'Automation Pump', 'subtitle': 'Pompa Penyiraman', 'component': 'pompa', 'isEnabled': false, 'color': Colors.blue},
    {'icon': Icons.lightbulb_rounded, 'title': 'Lampu Penghangat', 'subtitle': 'Pemanas Kandang', 'component': 'lampu', 'isEnabled': false, 'color': Colors.amber},
    {'icon': Icons.wind_power_rounded, 'title': 'Kipas Exhaust', 'subtitle': 'Ventilasi Udara', 'component': 'kipas', 'isEnabled': false, 'color': Colors.blue},
    {'icon': Icons.grain_rounded, 'title': 'Pakan', 'subtitle': 'Sistem Pakan', 'component': 'pakan_otomatis', 'isEnabled': false, 'color': Colors.orange},
  ];

  @override
  void initState() {
    super.initState();
    _setDynamicGreeting();
    _loadUserProfile();
    _initializeAppData();
    _loadToggleStates();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _setDynamicGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 11) _greeting = 'Selamat Pagi';
    else if (hour >= 11 && hour < 15) _greeting = 'Selamat Siang';
    else if (hour >= 15 && hour < 18) _greeting = 'Selamat Sore';
    else _greeting = 'Selamat Malam';
  }

  // --- LOGIKA DATA ---
  Future<void> _initializeAppData() async {
    await _fetchActiveDevice();
    if (_activeDeviceId != null) {
      _refreshAllData();
      // Jalankan polling tiap 5 detik
      _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) => _refreshAllData());
    }
  }

<<<<<<< HEAD
  // --- 2. LOGIKA NAMA & FOTO USER API (/users/me) via DioClient ---
  Future<void> _loadUserProfile() async {
    try {
      final response = await _dio.get(ApiConfig.usersUrl);

      final data = response.data;
      String fetchedName = data['full_name'] ?? data['name'] ?? data['email'].toString().split('@')[0] ?? 'Peternak';
      String fetchedPic = data['picture'] ?? '';

      // Backfill user UUID into TokenManager.
      final String? userId = data['id'] as String?;
      if (userId != null && userId.isNotEmpty) {
        final tokenManager = TokenManager();
        final existingId = await tokenManager.getUserId();
        if (existingId == null || existingId.isEmpty) {
          await tokenManager.saveUserInfo(
            id: userId,
            email: data['email'] as String? ?? '',
            role: data['role'] as String? ?? '',
          );
        }
      }

      if (mounted) {
        setState(() {
          _userName = fetchedName;
          _pictureUrl = fetchedPic;
        });
      }
    } on DioException catch (_) {
      // 401 triggers global logout via interceptor; other errors are non-fatal here
      if (mounted) setState(() => _userName = 'Peternak');
    } catch (e) {
      developer.log('✗ Error loading profile: $e', name: 'HomeScreen');
      if (mounted) setState(() => _userName = 'Peternak');
    }
  }

  // --- 3. LOGIKA MENCARI DEVICE & CEK STATUS & CEK NOTIF (via DioClient) ---
  Future<void> _initializeDeviceStatus() async {
    try {
      final response = await _dio.get(ApiConfig.devicesUrl);

      final data = response.data;
      // Backend returns paginated response: { data: [...], total: N, ... }
      final List devices = data is Map ? (data['data'] as List? ?? []) : (data is List ? data : []);
      if (devices.isNotEmpty) {
        _activeDeviceId = devices[0]['id'].toString();

        await _checkOnlineStatus();
        await _fetchNotifications();

        _statusTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
          _checkOnlineStatus();
          _fetchNotifications();
        });
      } else {
        if (mounted) {
          setState(() {
            _isCheckingStatus = false;
            _isDeviceOnline = false;
          });
        }
      }
    } on DioException catch (_) {
      // 401 triggers global logout via interceptor; other errors are non-fatal
      if (mounted) {
        setState(() {
          _isCheckingStatus = false;
          _isDeviceOnline = false;
        });
      }
    } catch (e) {
      developer.log('✗ Error initializing device status: $e', name: 'HomeScreen');
      if (mounted) {
        setState(() {
          _isCheckingStatus = false;
          _isDeviceOnline = false;
        });
      }
    }
=======
  void _refreshAllData() {
    _checkOnlineStatus();
    _fetchSensorData();
    _fetchNotifications();
  }

  Future<void> _fetchActiveDevice() async {
    try {
      final token = await _secureStorage.read(key: 'jwt_token');
      final response = await http.get(Uri.parse('https://api.pcb.my.id/devices/'), headers: {'Authorization': 'Bearer $token'});
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List && data.isNotEmpty) {
          setState(() => _activeDeviceId = data[0]['id'].toString());
        }
      }
    } catch (e) { debugPrint("Error Device: $e"); }
>>>>>>> upstream/main
  }

  Future<void> _checkOnlineStatus() async {
    if (_activeDeviceId == null) return;
    try {
<<<<<<< HEAD
      final response = await _dio.get(ApiConfig.deviceStatusUrl(_activeDeviceId!));
      final data = response.data;
      if (mounted) {
=======
      final token = await _secureStorage.read(key: 'jwt_token');
      final response = await http.get(Uri.parse('https://api.pcb.my.id/devices/$_activeDeviceId/status'), headers: {'Authorization': 'Bearer $token'});
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
>>>>>>> upstream/main
        setState(() {
          _isDeviceOnline = data['is_online'] ?? false;
          _isCheckingStatus = false;
        });
      }
<<<<<<< HEAD
    } on DioException catch (_) {
      if (mounted) {
        setState(() {
          _isDeviceOnline = false;
          _isCheckingStatus = false;
        });
=======
    } catch (_) { setState(() => _isCheckingStatus = false); }
  }

  Future<void> _fetchSensorData() async {
    if (_activeDeviceId == null) return;
    try {
      final token = await _secureStorage.read(key: 'jwt_token');
      final response = await http.get(Uri.parse('https://api.pcb.my.id/devices/$_activeDeviceId/logs'), headers: {'Authorization': 'Bearer $token'});
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List && data.isNotEmpty) {
          setState(() {
            _temp = data[0]['temperature']?.toString() ?? '--';
            _humi = data[0]['humidity']?.toString() ?? '--';
            _amo = data[0]['ammonia']?.toString() ?? '--';
            _isSensorLoading = false;
          });
        }
>>>>>>> upstream/main
      }
    } catch (e) { debugPrint("Error Sensor: $e"); }
  }

  // --- MEMBACA STATUS TOGGLE TERAKHIR DARI MEMORI HP ---
  Future<void> _loadToggleStates() async {
    for (int i = 0; i < _controlItems.length; i++) {
      String component = _controlItems[i]['component'];
      String? savedState = await _secureStorage.read(key: 'toggle_$component');

      if (savedState != null) {
        setState(() {
          _controlItems[i]['isEnabled'] = (savedState == 'true');
        });
      }
    }
  }

<<<<<<< HEAD
  // --- 4. LOGIKA AMBIL NOTIFIKASI ALERTS (via DioClient) ---
  Future<void> _fetchNotifications() async {
    if (_activeDeviceId == null) return;
    try {
      final response = await _dio.get(ApiConfig.deviceAlertsUrl(_activeDeviceId!));

      final data = response.data;
      // Backend returns paginated response: { data: [...], total: N, ... }
      final List alerts = data is Map ? (data['data'] as List? ?? []) : (data is List ? data : []);
      if (mounted) {
        setState(() {
          _notifications = alerts;
          _notificationCount = alerts.length;
        });
=======
  // FUNGSI TOGGLE (DIPANGGIL DARI HOMEPAGE)
  // FUNGSI TOGGLE (DIPANGGIL DARI HOMEPAGE)
  Future<void> _handleToggle(int index, bool newValue) async {
    if (_activeDeviceId == null || !_isDeviceOnline) return;

    final component = _controlItems[index]['component'];
    final originalValue = _controlItems[index]['isEnabled'];

    setState(() => _controlItems[index]['isEnabled'] = newValue); // Optimistic Update

    try {
      final token = await _secureStorage.read(key: 'jwt_token');
      final response = await http.post(
        Uri.parse('https://api.pcb.my.id/devices/$_activeDeviceId/control'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode({'component': component, 'state': newValue}),
      );

      if (response.statusCode != 200) {
        throw Exception("Failed");
      } else {
        // JIKA SUKSES KE SERVER, SIMPAN STATUSNYA KE MEMORI HP
        await _secureStorage.write(key: 'toggle_$component', value: newValue.toString());
      }
    } catch (e) {
      setState(() => _controlItems[index]['isEnabled'] = originalValue); // Revert jika gagal
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gagal mengontrol alat!")));
      }
    }
  }

  // --- LOGIKA PROFIL USER ---
  Future<void> _loadUserProfile() async {
    try {
      final token = await _secureStorage.read(key: 'jwt_token');
      if (token == null) return;

      final response = await http.get(
        Uri.parse('https://api.pcb.my.id/users/me'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            // Sesuaikan key JSON dengan response backend lu (name/full_name)
            _userName = data['full_name'] ?? data['name'] ?? 'Peternak';
            _pictureUrl = data['picture'] ?? '';
          });
        }
      }
    } catch (e) {
      debugPrint("Error load profile: $e");
    }
  }

  // --- LOGIKA NOTIFIKASI ---
  Future<void> _fetchNotifications() async {
    if (_activeDeviceId == null) return;
    try {
      final token = await _secureStorage.read(key: 'jwt_token');
      final response = await http.get(
        Uri.parse('https://api.pcb.my.id/devices/$_activeDeviceId/alerts'),
        headers: {'Authorization': 'Bearer $token'},
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _notifications = data;
            _notificationCount = data.length;
          });
        }
>>>>>>> upstream/main
      }
    } on DioException catch (_) {
      // Non-fatal — silently fail for background polling
    } catch (e) {
<<<<<<< HEAD
      developer.log('✗ Error fetching notifications: $e', name: 'HomeScreen');
=======
      debugPrint("Error fetching alerts: $e");
>>>>>>> upstream/main
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _currentIndex == 0 ? _buildAppBar() : null,
      body: Column(
        children: [
          Expanded(child: _buildPageContent()),
          FloatingNavBar(
            currentIndex: _currentIndex,
            onItemSelected: (index) => setState(() => _currentIndex = index),
          ),
        ],
      ),
    );
  }

  Widget _buildPageContent() {
    switch (_currentIndex) {
      case 0:
        return HomePage(
          deviceId: _activeDeviceId,
          isOnline: _isDeviceOnline,
          temperature: _temp,
          humidity: _humi,
          ammonia: _amo,
          isSensorLoading: _isSensorLoading,
          controlItems: _controlItems,
          onToggle: _handleToggle, // Lempar fungsi kontrol ke body
        );
      case 1: return const DevicesPage();
      case 2: return const ScanPage();
      case 3: return const HistoryPage();
      case 4: return const ProfilePage();
      default: return const HomePage(isOnline: false, temperature: '--', humidity: '--', ammonia: '--', isSensorLoading: true, controlItems: [], onToggle: null);
    }
  }

  PreferredSizeWidget _buildAppBar() {
    Color badgeColor = _isCheckingStatus ? Colors.grey : (_isDeviceOnline ? Colors.green : Colors.red);
    return AppBar(
      backgroundColor: const Color(0xFF4A3728),
      elevation: 0,
      toolbarHeight: 80,
      automaticallyImplyLeading: false,
      flexibleSpace: Padding(
        padding: const EdgeInsets.fromLTRB(14, 40, 14, 10),
        child: Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundImage: _pictureUrl.isNotEmpty ? NetworkImage(_pictureUrl) : null,
              child: _pictureUrl.isEmpty ? const Icon(Icons.person) : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_greeting, style: const TextStyle(fontSize: 11, color: Color(0xFFD4A574))),
                  Text('Hai, $_userName', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10)),
              child: Row(
                children: [
                  CircleAvatar(radius: 3, backgroundColor: badgeColor),
                  const SizedBox(width: 4),
                  Text(_isCheckingStatus ? 'CEK' : (_isDeviceOnline ? 'ONLINE' : 'OFFLINE'), style: const TextStyle(fontSize: 9, color: Colors.white)),
                ],
              ),
            ),
            IconButton(
              icon: Badge(
                label: Text('$_notificationCount'),
                isLabelVisible: _notificationCount > 0,
                child: const Icon(Icons.notifications_none, color: Colors.white),
              ),
              onPressed: () {}, // Panggil BottomSheet di sini
            ),
          ],
        ),
      ),
    );
  }
<<<<<<< HEAD

  Widget _buildPageContent() {
    switch (_currentIndex) {
      case 0: return const DeviceListPage();
      case 1: return const DevicesPage();
      case 2: return const ScanPage();
      case 3: return const HistoryPage();
      case 4: return const ProfilePage();
      default: return const DeviceListPage();
    }
  }
=======
>>>>>>> upstream/main
}