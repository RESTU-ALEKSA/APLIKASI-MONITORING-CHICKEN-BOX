import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../constants/app_colors.dart';
import '../routes/app_routes.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _fullName = 'Memuat...';
  String _email = 'Memuat...';
  String _pictureUrl = '';
  bool _isLoadingProfile = true;
  List<dynamic> _myDevices = [];
  bool _isLoadingDevices = true;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
    _fetchMyDevices();
  }

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
          _isLoadingProfile = false;
        });
      }
    }
  }

  Future<void> _fetchMyDevices() async {
    setState(() => _isLoadingDevices = true);
    try {
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
      if (mounted) setState(() => _isLoadingDevices = false);
    }
  }

  // --- 2. FITUR EDIT NAMA ---
  Future<void> _showEditNameDialog() async {
    final TextEditingController nameController = TextEditingController(text: _fullName);
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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
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
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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

                const SizedBox(height: 40),

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
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}