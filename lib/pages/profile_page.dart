import 'package:flutter/material.dart';
<<<<<<< HEAD
import 'dart:developer' as developer;
import 'package:dio/dio.dart';
=======
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
>>>>>>> upstream/main
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/app_colors.dart';
import '../constants/api_config.dart';
import '../core/network/dio_client.dart';
import '../core/network/token_manager.dart';
import '../core/network/api_exception.dart';
import '../services/auth_service.dart';
import '../utils/error_handler.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final Dio _dio = DioClient().dio;
  final AuthService _authService = AuthService();
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseAuth _auth = FirebaseAuth.instance;

<<<<<<< HEAD
  // State Data Profil
=======
>>>>>>> upstream/main
  String _fullName = 'Memuat...';
  String _email = 'Memuat...';
  String _pictureUrl = '';
  bool _isLoadingProfile = true;
<<<<<<< HEAD

  // State Daftar Perangkat
=======
>>>>>>> upstream/main
  List<dynamic> _myDevices = [];
  bool _isLoadingDevices = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchUserProfile();
      _fetchMyDevices();
    });
  }

<<<<<<< HEAD
  // --- 1. AMBIL DATA PROFIL DARI BACKEND (via DioClient) ---
  Future<void> _fetchUserProfile() async {
    try {
      final response = await _dio.get(ApiConfig.usersUrl);

      final data = response.data;
      if (mounted) {
        setState(() {
          _fullName = data['full_name'] ?? data['name'] ?? 'Peternak';
          _email = data['email'] ?? 'Email tidak tersedia';
          _pictureUrl = data['picture'] ?? '';
=======
  // --- 1. DATA FETCHING ---
  // --- 1. DATA FETCHING ---
  Future<void> _fetchUserProfile() async {
    try {
      final token = await _secureStorage.read(key: 'jwt_token');
      if (token == null) {
        throw Exception("Token tidak ditemukan");
      }

      final response = await http.get(
        Uri.parse('https://api.pcb.my.id/users/me'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      // Tambahkan print ini untuk melihat isi asli dari backend
      debugPrint("RESPONSE /users/me: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        if (mounted) {
          setState(() {
            // Cek berbagai variasi penamaan key yang mungkin keluar dari backend
            _fullName = data['full_name'] ?? data['name'] ?? 'Peternak Kandang';
            _email = data['email'] ?? 'Email tidak ditemukan';
            _pictureUrl = data['picture'] ?? data['avatar'] ?? '';
            _isLoadingProfile = false;
          });
        }
      } else {
        // Kalau status bukan 200 (misal 401 Unauthorized)
        debugPrint("GAGAL FETCH PROFIL: ${response.statusCode} - ${response.body}");
        throw Exception("Gagal memuat profil: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("ERROR FETCH PROFIL CATCH: $e");
      if (mounted) {
        setState(() {
          _fullName = 'Gagal memuat profil';
          _email = 'Silakan coba lagi';
>>>>>>> upstream/main
          _isLoadingProfile = false;
        });
      }
    } on DioException catch (e) {
      developer.log('✗ Error loading profile: ${e.error}', name: 'ProfilePage');
      if (mounted) setState(() => _isLoadingProfile = false);
    } catch (e) {
      developer.log('✗ Error loading profile: $e', name: 'ProfilePage');
      if (mounted) setState(() => _isLoadingProfile = false);
    }
  }

<<<<<<< HEAD
  // --- 2. AMBIL DAFTAR KANDANG MILIK USER (via DioClient) ---
=======
>>>>>>> upstream/main
  Future<void> _fetchMyDevices() async {
    if (!mounted) return;
    setState(() => _isLoadingDevices = true);

    try {
<<<<<<< HEAD
      final response = await _dio.get(ApiConfig.devicesUrl);

      // Backend returns paginated response: { data: [...], total: N, ... }
      final data = response.data;
      if (mounted) {
        setState(() {
          _myDevices = data is Map ? (data['data'] as List? ?? []) : (data as List? ?? []);
          _isLoadingDevices = false;
        });
      }
    } on DioException catch (e) {
      developer.log('✗ Error fetching devices: ${e.error}', name: 'ProfilePage');
      if (mounted) setState(() => _isLoadingDevices = false);
    } catch (e) {
      developer.log('✗ Error fetching devices: $e', name: 'ProfilePage');
=======
      final token = await _secureStorage.read(key: 'jwt_token');
      final response = await http.get(
        Uri.parse('https://api.pcb.my.id/devices/'),
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
      );
      if (response.statusCode == 200 && mounted) {
        setState(() {
          _myDevices = jsonDecode(response.body);
          _isLoadingDevices = false;
        });
      }
    } finally {
>>>>>>> upstream/main
      if (mounted) setState(() => _isLoadingDevices = false);
    }
  }

<<<<<<< HEAD
  // --- 3. FUNGSI UNCLAIM (LEPAS KANDANG) via DioClient ---
  Future<void> _unclaimDevice(String deviceId) async {
    _showLoadingDialog();

    try {
      await _dio.post(ApiConfig.deviceUnclaimUrl(deviceId));

      if (!mounted) return;
      Navigator.pop(context);
      _showSnackBar('Kandang berhasil dilepas.', isError: false);
      _fetchMyDevices();
    } on DioException catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      if (e.error is ApiException) {
        ErrorHandler.handleApiException(context, e.error as ApiException);
      } else {
        _showSnackBar('Kesalahan jaringan: ${e.message}');
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      _showSnackBar('Kesalahan jaringan: $e');
    }
  }

  // --- 4. FUNGSI RESET/GANTI PASSWORD ---
  Future<void> _handleResetPassword() async {
    if (_email == 'Memuat...' || _email.isEmpty) {
      _showSnackBar('Data email belum siap.');
      return;
    }

    _showLoadingDialog();

    try {
      await _auth.sendPasswordResetEmail(email: _email);
      if (mounted) Navigator.pop(context); // Tutup loading
      _showSnackBar('Link ganti password telah dikirim ke email $_email', isError: false);
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _showSnackBar('Gagal mengirim link: $e');
    }
  }

  // --- 5. FUNGSI HAPUS AKUN (PERMANEN) via DioClient ---
  Future<void> _handleDeleteAccount() async {
    _showLoadingDialog();

    try {
      await _dio.delete(ApiConfig.usersUrl);

      if (!mounted) return;
      Navigator.pop(context);

      try { await _auth.currentUser?.delete(); } catch (_) {}
      await _clearLocalDataAndLogout();
    } on DioException catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      if (e.error is ApiException) {
        ErrorHandler.handleApiException(context, e.error as ApiException);
      } else {
        _showSnackBar('Terjadi kesalahan jaringan: ${e.message}');
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      _showSnackBar('Terjadi kesalahan jaringan: $e');
    }
  }

  // --- 6. LOGIKA CLEANUP & LOGOUT (via AuthService + Global Listener) ---
  Future<void> _clearLocalDataAndLogout() async {
    try {
      // Clear backend JWT via AuthService (clears TokenManager)
      await _authService.logout();
      // Clear Firebase and Google sessions
      try { await _auth.signOut(); } catch (_) {}
      try { await _googleSignIn.signOut(); } catch (_) {}

      developer.log('✓ Logout cleanup complete', name: 'ProfilePage');
    } finally {
      // Trigger the global logout event — the listener in main.dart
      // handles navigation to LoginPage via navigatorKey.
      // This is the SINGLE navigation path for all logout scenarios.
      TokenManager().triggerLogout();
    }
  }

  // --- HELPER UI ---
  void _showLoadingDialog() {
=======
  // --- 2. FITUR EDIT NAMA ---
  Future<void> _showEditNameDialog() async {
    final TextEditingController nameController = TextEditingController(text: _fullName);
>>>>>>> upstream/main
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ubah Nama Lengkap'),
        content: TextField(controller: nameController, decoration: const InputDecoration(hintText: "Masukkan nama baru")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              final newName = nameController.text.trim();
              if (newName.isEmpty) return;
              Navigator.pop(context);
              await _updateName(newName);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
<<<<<<< HEAD
  }

  void _showSnackBar(String msg, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: isError ? AppColors.error : AppColors.primaryGreen, behavior: SnackBarBehavior.floating),
    );
  }

=======
  }

  Future<void> _updateName(String newName) async {
    try {
      final token = await _secureStorage.read(key: 'jwt_token');
      // Update di Firebase
      await _auth.currentUser?.updateDisplayName(newName);
      // Update di FastAPI
      final response = await http.patch(
        Uri.parse('https://api.pcb.my.id/users/me?full_name=$newName'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        setState(() => _fullName = newName);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Nama berhasil diperbarui")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gagal memperbarui nama")));
    }
  }

  // --- 3. FITUR RESET PASSWORD ---
  Future<void> _handleResetPassword() async {
    try {
      await _auth.sendPasswordResetEmail(email: _email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Link reset password telah dikirim ke email Anda"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gagal mengirim email reset")));
    }
  }

  // --- 4. FITUR HAPUS AKUN ---
  Future<void> _showDeleteAccountConfirmation() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Akun Permanent?', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: const Text('Tindakan ini tidak bisa dibatalkan. Semua data kandang Anda akan hilang.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              await _deleteAccount();
            },
            child: const Text('Ya, Hapus Akun', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount() async {
    try {
      final token = await _secureStorage.read(key: 'jwt_token');
      // 1. Hapus di Backend
      await http.delete(Uri.parse('https://api.pcb.my.id/users/me'), headers: {'Authorization': 'Bearer $token'});
      // 2. Hapus di Firebase
      await _auth.currentUser?.delete();
      // 3. Logout & Bersihkan Storage
      _handleLogout(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Untuk alasan keamanan, silakan login ulang sebelum menghapus akun.")));
    }
  }

  // --- LOGOUT & UNCLAIM (Sesuai kode lama lo) ---
  Future<void> _unclaimDevice(String deviceId) async { /* ... kode lama lo ... */ }
  Future<void> _handleLogout(BuildContext context) async {
    await _secureStorage.deleteAll();
    await _googleSignIn.signOut();
    await _auth.signOut();
    if (mounted) Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
  }

>>>>>>> upstream/main
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
<<<<<<< HEAD
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 40),
            decoration: const BoxDecoration(
              color: AppColors.darkBackground,
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 55,
                  backgroundColor: Colors.white24,
                  child: ClipOval(
                    child: _pictureUrl.isNotEmpty
                        ? Image.network(_pictureUrl, width: 110, height: 110, fit: BoxFit.cover, 
                            errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 60, color: Colors.white))
                        : const Icon(Icons.person, size: 60, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 16),
                Text(_fullName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                Text(_email, style: const TextStyle(fontSize: 14, color: Colors.white70)),
=======
          // Header Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 40),
            decoration: const BoxDecoration(color: AppColors.darkBackground, borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30))),
            child: Column(
              children: [
                GestureDetector(
                  onTap: _showEditNameDialog, // Klik nama/foto untuk ganti nama
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white24,
                    backgroundImage: _pictureUrl.isNotEmpty ? NetworkImage(_pictureUrl) : null,
                    child: _pictureUrl.isEmpty ? const Icon(Icons.person, size: 50, color: Colors.white) : null,
                  ),
                ),
                const SizedBox(height: 15),
                Text(_fullName, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                Text(_email, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 10),
                ActionChip(
                  label: const Text("Edit Nama", style: TextStyle(color: Colors.white, fontSize: 12)),
                  backgroundColor: AppColors.primaryGreen,
                  onPressed: _showEditNameDialog,
                  avatar: const Icon(Icons.edit, size: 16, color: Colors.white),
                ),
>>>>>>> upstream/main
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
<<<<<<< HEAD
                const Text('KANDANG SAYA', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                const SizedBox(height: 12),

                if (_isLoadingDevices)
                  const Center(child: CircularProgressIndicator())
                else if (_myDevices.isEmpty)
                  _buildEmptyState()
                else
                  ..._myDevices.map((d) => _buildDeviceCard(d)),
=======
                const Text('PENGATURAN KEAMANAN', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 10),

                // Tombol Reset Password
                ListTile(
                  tileColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  leading: const Icon(Icons.lock_reset_rounded, color: AppColors.primaryGreen),
                  title: const Text("Ubah Password"),
                  subtitle: const Text("Kirim link ubah password ke email"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: _handleResetPassword,
                ),

                const SizedBox(height: 30),
                const Text('KANDANG SAYA', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 10),

                // Daftar Device (Mapping dari kode lama lo)
                if (_isLoadingDevices) const Center(child: CircularProgressIndicator())
                else ..._myDevices.map((d) => Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: const Icon(Icons.home_work, color: AppColors.primaryGreen),
                    title: Text(d['name']),
                    subtitle: Text(d['mac_address']),
                    trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _unclaimDevice(d['id'].toString())),
                  ),
                )),
>>>>>>> upstream/main

                const SizedBox(height: 40),

<<<<<<< HEAD
                // Tombol Ganti Password
                _buildActionButton(
                  label: 'Ganti Password via Email',
                  icon: Icons.lock_reset_rounded,
                  color: AppColors.primaryBlue,
                  onTap: () => _showConfirmDialog(
                    title: 'Ganti Password',
                    msg: 'Sistem akan mengirimkan link pengaturan ulang password ke email Anda ($_email). Lanjutkan?',
                    onConfirm: _handleResetPassword,
                  ),
                ),
                
                const SizedBox(height: 12),

                // Tombol Keluar Akun
                _buildActionButton(
                  label: 'Keluar Akun',
                  icon: Icons.logout_rounded,
                  color: AppColors.statusAlert,
                  onTap: () => _showConfirmDialog(
                    title: 'Konfirmasi Logout',
                    msg: 'Apakah Anda yakin ingin keluar?',
                    onConfirm: _clearLocalDataAndLogout,
                  ),
                ),

                const SizedBox(height: 12),

                Center(
                  child: TextButton(
                    onPressed: () => _showConfirmDialog(
                      title: 'Hapus Akun',
                      msg: 'Tindakan ini permanen. Semua data kandang dan riwayat akan hilang selamanya.',
                      confirmText: 'Hapus Selamanya',
                      onConfirm: _handleDeleteAccount,
                    ),
                    child: const Text('Hapus Akun Selamanya', style: TextStyle(color: Colors.grey, fontSize: 12, decoration: TextDecoration.underline)),
=======
                // Logout Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white, side: const BorderSide(color: Colors.red), padding: const EdgeInsets.symmetric(vertical: 15)),
                    onPressed: () => _handleLogout(context),
                    child: const Text("Keluar Akun", style: TextStyle(color: Colors.red)),
                  ),
                ),

                // Tombol Hapus Akun (Gaya teks saja agar tidak terlalu mencolok tapi tersedia)
                Center(
                  child: TextButton(
                    onPressed: _showDeleteAccountConfirmation,
                    child: const Text("Hapus Akun Selamanya", style: TextStyle(color: Colors.grey, fontSize: 12, decoration: TextDecoration.underline)),
>>>>>>> upstream/main
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
<<<<<<< HEAD

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: AppColors.borderLight)),
      child: const Text('Belum ada kandang terdaftar.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
    );
  }

  Widget _buildDeviceCard(Map<String, dynamic> d) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: const BorderSide(color: AppColors.borderLight)),
      child: ListTile(
        leading: const Icon(Icons.home_work_rounded, color: AppColors.primaryGreen),
        title: Text(d['name'] ?? 'Kandang Tanpa Nama', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('MAC: ${d['mac_address']}', style: const TextStyle(fontSize: 12)),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: AppColors.statusAlert),
          onPressed: () => _showConfirmDialog(
            title: 'Lepas Kandang',
            msg: 'Lepas "${d['name']}" dari akun Anda?',
            onConfirm: () => _unclaimDevice(d['id'].toString()),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({required String label, required IconData icon, required Color color, required VoidCallback onTap}) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color),
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: onTap,
        icon: Icon(icon, color: color, size: 20),
        label: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _showConfirmDialog({required String title, required String msg, String confirmText = 'Ya, Lanjutkan', required VoidCallback onConfirm}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(msg),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen),
            onPressed: () { 
              Navigator.pop(context); 
              onConfirm(); 
            },
            child: Text(confirmText, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
=======
>>>>>>> upstream/main
}