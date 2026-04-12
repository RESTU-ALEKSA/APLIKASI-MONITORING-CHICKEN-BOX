import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../routes/app_routes.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ── FUNGSI LOGIN EMAIL & PASSWORD ──
  Future<void> _handleEmailLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Email dan password tidak boleh kosong.'),
          backgroundColor: Colors.red.shade800,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Login pakai Firebase
      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      final User? user = userCredential.user;
      if (user != null) {
        // Cek apakah email sudah diverifikasi? (Opsional)
        // if (!user.emailVerified) {
        //    await FirebaseAuth.instance.signOut();
        //    throw Exception("Email belum diverifikasi. Cek inbox/spam kamu!");
        // }

        // 2. Kalau aman, minta token dan lempar ke backend
        final String? firebaseToken = await user.getIdToken();
        if (firebaseToken != null) {
          await _exchangeTokenWithBackend(firebaseToken);
        }
      }
    } on FirebaseAuthException catch (e) {
      String pesanError = 'Login gagal.';
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
        pesanError = 'Email atau password salah.';
      } else if (e.code == 'invalid-email') {
        pesanError = 'Format email tidak valid.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(pesanError),
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

  // ── FUNGSI LUPA PASSWORD (POP-UP) ──
  Future<void> _showForgotPasswordDialog() async {
    final TextEditingController resetEmailController =
    TextEditingController(text: _emailController.text);

    showDialog(
      context: context, // Ini Context milik LoginPage
      builder: (dialogContext) { // UBAH NAMA INI JADI dialogContext
        return AlertDialog(
          backgroundColor: const Color(0xFFEBEBEB),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Reset Password',
            style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A)),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Masukkan email yang terdaftar. Kami akan mengirimkan link untuk membuat password baru.',
                style: TextStyle(fontSize: 13, color: Color(0xFF666666)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: resetEmailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A1A)),
                decoration: InputDecoration(
                  hintText: 'Email kamu',
                  hintStyle: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 14),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(), // Tutup pakai dialogContext
              child: const Text('Batal', style: TextStyle(color: Color(0xFF888888))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5C4033),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              onPressed: () async {
                final email = resetEmailController.text.trim();
                if (email.isEmpty) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: const Text('Email harus diisi!'),
                      backgroundColor: Colors.red.shade800,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }

                // 1. TANGKAP MESSENGER DARI HALAMAN UTAMA (context)
                // Lakukan ini sebelum menutup dialog agar aman
                final messenger = ScaffoldMessenger.of(context);

                // 2. Tutup dialognya
                Navigator.of(dialogContext).pop();

                setState(() => _isLoading = true);

                try {
                  await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

                  if (mounted) {
                    // 3. GUNAKAN MESSENGER YANG SUDAH DITANGKAP
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Email sudah dikirim, silakan cek di kotak utama atau folder spam.'),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 5),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } on FirebaseAuthException catch (e) {
                  String pesan = 'Terjadi kesalahan.';
                  if (e.code == 'user-not-found') {
                    pesan = 'Email tidak terdaftar di sistem kami.';
                  } else if (e.code == 'invalid-email') {
                    pesan = 'Format email tidak valid.';
                  }
                  if (mounted) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(pesan),
                        backgroundColor: Colors.red.shade800,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } finally {
                  if (mounted) setState(() => _isLoading = false);
                }
              },
              child: const Text('Kirim Link', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  // ── FUNGSI LOGIN GOOGLE ──
  Future<void> _handleGoogleLogin() async {
    setState(() => _isLoading = true);

    try {
      await _googleSignIn.signOut();
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
      await FirebaseAuth.instance.signInWithCredential(credential);
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

  // ── FUNGSI TUKAR TOKEN KE BACKEND ──
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
      throw Exception(
          'Backend menolak login: ${response.statusCode} - ${response.body}');
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
                // ── HEADER (coklat) ──
                Container(
                  color: const Color(0xFF5C4033),
                  width: double.infinity,
                  padding: const EdgeInsets.only(top: 40, bottom: 0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.08),
                      Column(
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: 140,
                                height: 140,
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
                                    'assets/images/logo.png',
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
                                            size: 70,
                                            color: Color(0xFFFF8C00),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              Positioned(
                                top: -10,
                                right: -10,
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF1976D2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.wifi,
                                    size: 24,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          const Text(
                            'KANDANG PINTAR',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 2.0,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Monitoring Ternak Lebih Efisien',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFFC0C0C0),
                              letterSpacing: 0.3,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.08),
                    ],
                  ),
                ),

                // ── WAVY DIVIDER ──
                SizedBox(
                  width: double.infinity,
                  height: 80,
                  child: CustomPaint(painter: WavyDividerPainter()),
                ),

                // ── FORM AREA (abu-abu terang) ──
                Container(
                  color: const Color(0xFFEBEBEB),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'Log In',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1A1A1A),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Masukkan username dan password kalian.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF666666),
                          height: 1.6,
                          letterSpacing: 0.2,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── EMAIL / USERNAME FIELD ──
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF1A1A1A),
                        ),
                        decoration: InputDecoration(
                          hintText: 'Username Or Email',
                          hintStyle: const TextStyle(
                            color: Color(0xFFAAAAAA),
                            fontSize: 14,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 16),
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
                            borderSide: const BorderSide(
                                color: Color(0xFF5C4033), width: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // ── PASSWORD FIELD ──
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF1A1A1A),
                        ),
                        decoration: InputDecoration(
                          hintText: 'Password',
                          hintStyle: const TextStyle(
                            color: Color(0xFFAAAAAA),
                            fontSize: 14,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 16),
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
                            borderSide: const BorderSide(
                                color: Color(0xFF5C4033), width: 1.5),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: const Color(0xFFAAAAAA),
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() => _obscurePassword = !_obscurePassword);
                            },
                          ),
                        ),
                      ),

                      // ── TOMBOL LUPA PASSWORD ──
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: _showForgotPasswordDialog,
                          child: const Text(
                            'Lupa Password?',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF5C4033),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── TOMBOL MASUK ──
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleEmailLogin,
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
                            'Masuk',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // ── LINK KE REGISTER ──
                      GestureDetector(
                        onTap: () => Navigator.of(context).pushNamed(AppRoutes.register),
                        child: RichText(
                          text: const TextSpan(
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF888888),
                            ),
                            children: [
                              TextSpan(text: 'Belum punya akun? '),
                              TextSpan(
                                text: 'Daftar di sini',
                                style: TextStyle(
                                  color: Color(0xFF5C4033),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── DIVIDER OR ──
                      Row(
                        children: [
                          Expanded(
                              child: Container(height: 1, color: const Color(0xFFCCCCCC))),
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
                          Expanded(
                              child: Container(height: 1, color: const Color(0xFFCCCCCC))),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // ── TOMBOL GOOGLE ──
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleGoogleLogin,
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
                                width: 24,
                                height: 24,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.account_circle,
                                    size: 24,
                                    color: Color(0xFF1F2937),
                                  );
                                },
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Masuk dengan Google',
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
                      const SizedBox(height: 18),

                      // ── FOOTER TEXT ──
                      RichText(
                        text: const TextSpan(
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF888888),
                            letterSpacing: 0.1,
                            height: 1.5,
                          ),
                          children: [
                            TextSpan(text: 'Dengan masuk, kamu menyetujui '),
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
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── DEKORASI LINGKARAN ──
          Positioned(
            top: 25,
            left: -25,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 3,
                ),
              ),
            ),
          ),
          Positioned(
            top: 80,
            right: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 3,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 180,
            left: -35,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class WavyDividerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final brownPaint = Paint()
      ..color = const Color(0xFF5C4033)
      ..style = PaintingStyle.fill;

    final grayPaint = Paint()
      ..color = const Color(0xFFEBEBEB)
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      grayPaint,
    );

    final path = Path();
    path.moveTo(0, size.height * 0.4);

    double waveWidth = 80;
    double waveHeight = 40;

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
  bool shouldRepaint(WavyDividerPainter oldDelegate) => false;
}