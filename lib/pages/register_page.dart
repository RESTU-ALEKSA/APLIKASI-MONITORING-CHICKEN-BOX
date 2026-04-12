import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../routes/app_routes.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ── FUNGSI REGISTRASI FIREBASE + VERIFIKASI EMAIL ──
  Future<void> _handleRegister() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Semua kolom wajib diisi!'), backgroundColor: Colors.red.shade800),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Password tidak cocok!'), backgroundColor: Colors.red.shade800),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Buat user baru di Firebase
      final UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      final User? user = userCredential.user;

      if (user != null) {
        // 2. Update nama (display name) di profil Firebase
        await user.updateDisplayName(name);

        // 3. Kirim Email Verifikasi! ✉️
        if (!user.emailVerified) {
          await user.sendEmailVerification();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Registrasi sukses! Silakan cek inbox/spam email kamu untuk verifikasi.'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 5),
              ),
            );
          }
        }

        // 4. Ambil token Firebase dan kirim ke FastAPI kita
        final String? firebaseToken = await user.getIdToken();
        if (firebaseToken != null) {
          await _exchangeTokenWithBackend(firebaseToken);
        }
      }
    } on FirebaseAuthException catch (e) {
      String pesanError = 'Terjadi kesalahan Firebase.';
      if (e.code == 'weak-password') {
        pesanError = 'Password terlalu lemah (minimal 6 karakter).';
      } else if (e.code == 'email-already-in-use') {
        pesanError = 'Email ini sudah terdaftar.';
      } else if (e.code == 'invalid-email') {
        pesanError = 'Format email tidak valid.';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(pesanError), backgroundColor: Colors.red.shade800),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Terjadi kesalahan: $error'), backgroundColor: Colors.red.shade800),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── FUNGSI DAFTAR/LOGIN DENGAN GOOGLE ──
  Future<void> _handleGoogleRegister() async {
    setState(() => _isLoading = true);

    try {
      await _googleSignIn.signOut();
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        final String? firebaseToken = await user.getIdToken();
        if (firebaseToken != null) {
          await _exchangeTokenWithBackend(firebaseToken);
        }
      } else {
        throw Exception('Gagal mendapatkan user dari Firebase.');
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Firebase Error: ${e.message}'),
            backgroundColor: Colors.red.shade800,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan: $error'),
            backgroundColor: Colors.red.shade800,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Tembak token Firebase ke backend kita (sama seperti di LoginPage)
  Future<void> _exchangeTokenWithBackend(String firebaseToken) async {
    final response = await http.post(
      Uri.parse('https://api.pcb.my.id/auth/firebase/login'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({'id_token': firebaseToken}),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      final String backendToken = responseData['access_token'];
      await _secureStorage.write(key: 'jwt_token', value: backendToken);

      if (mounted) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.home);
      }
    } else {
      throw Exception('Backend menolak login: ${response.statusCode} - ${response.body}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                // ── DARK BROWN TOP AREA ──
                Container(
                  color: const Color(0xFF5C4033),
                  width: double.infinity,
                  padding: const EdgeInsets.only(top: 40, bottom: 0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: MediaQuery.of(context).size.height * 0.055),

                      // Back Button
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  width: 1.5,
                                ),
                              ),
                              child: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Logo + Title
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.4),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.asset(
                                'assets/images/logo.jpg',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.home,
                                        size: 55,
                                        color: Color(0xFFFF8C00),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          // WiFi Badge
                          Positioned(
                            top: -10,
                            right: -10,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Color(0xFF1976D2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.wifi,
                                size: 20,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'KANDANG PINTAR',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 2.0,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Monitoring Ternak Lebih Efisien',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFFC0C0C0),
                          letterSpacing: 0.3,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      SizedBox(height: MediaQuery.of(context).size.height * 0.055),
                    ],
                  ),
                ),

                // ── WAVY DIVIDER ──
                SizedBox(
                  width: double.infinity,
                  height: 80,
                  child: CustomPaint(painter: _WavyDividerPainter()),
                ),

                // ── FORM AREA ──
                Container(
                  color: const Color(0xFFEBEBEB),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      const Text(
                        'Daftar Akun',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1A1A1A),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Buat akun baru untuk mulai memantau kandang ayammu.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF666666),
                          height: 1.6,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 22),

                      // Nama Lengkap
                      _buildTextField(
                        controller: _nameController,
                        hint: 'Nama Lengkap',
                        keyboardType: TextInputType.name,
                      ),
                      const SizedBox(height: 12),

                      // Email
                      _buildTextField(
                        controller: _emailController,
                        hint: 'Email',
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 12),

                      // Password
                      _buildTextField(
                        controller: _passwordController,
                        hint: 'Password',
                        obscure: _obscurePassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: const Color(0xFFAAAAAA),
                            size: 20,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Konfirmasi Password
                      _buildTextField(
                        controller: _confirmPasswordController,
                        hint: 'Konfirmasi Password',
                        obscure: _obscureConfirm,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: const Color(0xFFAAAAAA),
                            size: 20,
                          ),
                          onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                        ),
                      ),
                      const SizedBox(height: 22),

                      // Daftar Button
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleRegister,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5C4033),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                              : const Text(
                            'Daftar',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // OR Divider
                      Row(
                        children: [
                          Expanded(child: Container(height: 1, color: const Color(0xFFCCCCCC))),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'OR',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF999999),
                                fontWeight: FontWeight.w500,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                          Expanded(child: Container(height: 1, color: const Color(0xFFCCCCCC))),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Google Register Button
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleGoogleRegister,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            elevation: 3,
                            shadowColor: Colors.black.withValues(alpha: 0.15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5C4033)),
                            ),
                          )
                              : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/images/google_logo.png',
                                width: 22,
                                height: 22,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.account_circle,
                                  size: 22,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Daftar dengan Google',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1F2937),
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Already have account
                      Center(
                        child: GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: RichText(
                            text: const TextSpan(
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF888888),
                              ),
                              children: [
                                TextSpan(text: 'Sudah punya akun? '),
                                TextSpan(
                                  text: 'Masuk',
                                  style: TextStyle(
                                    color: Color(0xFF5C4033),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Terms
                      RichText(
                        text: const TextSpan(
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF888888),
                            letterSpacing: 0.1,
                            height: 1.5,
                          ),
                          children: [
                            TextSpan(text: 'Dengan mendaftar, kamu menyetujui '),
                            TextSpan(
                              text: 'Syarat & Ketentuan',
                              style: TextStyle(
                                color: Color(0xFFC62828),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            TextSpan(text: ' serta Kebijakan Privasi Smart Kandang.'),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── DECORATIVE CIRCLES ──
          Positioned(
            top: 25,
            left: -25,
            child: _decorativeCircle(110),
          ),
          Positioned(
            top: 80,
            right: -30,
            child: _decorativeCircle(140),
          ),
          Positioned(
            bottom: 200,
            left: -35,
            child: _decorativeCircle(130),
          ),
        ],
      ),
    );
  }

  // ── HELPERS ──

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A1A)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 14),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Color(0xFF5C4033), width: 1.5),
        ),
        suffixIcon: suffixIcon,
      ),
    );
  }

  Widget _decorativeCircle(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 3,
        ),
      ),
    );
  }
}

// ── WAVY DIVIDER PAINTER ──

class _WavyDividerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final brownPaint = Paint()
      ..color = const Color(0xFF5C4033)
      ..style = PaintingStyle.fill;

    final grayPaint = Paint()
      ..color = const Color(0xFFEBEBEB)
      ..style = PaintingStyle.fill;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), grayPaint);

    final path = Path();
    path.moveTo(0, size.height * 0.4);

    const double waveWidth = 80;
    const double waveHeight = 40;

    for (double x = 0; x <= size.width; x += waveWidth) {
      path.quadraticBezierTo(
        x + waveWidth / 2,
        size.height * 0.4 - waveHeight,
        x + waveWidth,
        size.height * 0.4,
      );
    }

    path.lineTo(size.width, 0);
    path.lineTo(0, 0);
    path.close();

    canvas.drawPath(path, brownPaint);
  }

  @override
  bool shouldRepaint(_WavyDividerPainter oldDelegate) => false;
}