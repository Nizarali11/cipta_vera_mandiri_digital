import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignupView extends StatefulWidget {
  final VoidCallback onLoginTap;
  final TextEditingController usernameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final VoidCallback onSignupTap;
  const SignupView({
    super.key,
    required this.onLoginTap,
    required this.usernameController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.onSignupTap,
  });

  @override
  State<SignupView> createState() => _SignupViewState();
}

class _SignupViewState extends State<SignupView> {
  bool _obscurePassword = true;
  bool _loading = false;

  Future<void> _handleSignup() async {
    final username = widget.usernameController.text.trim();
    final email = widget.emailController.text.trim();
    final pass = widget.passwordController.text.trim();
    final confirm = widget.confirmPasswordController.text.trim();

    String? error;
    if (username.isEmpty) error = 'Username wajib diisi';
    else if (email.isEmpty) error = 'Email wajib diisi';
    else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) error = 'Format email tidak valid';
    else if (pass.length < 6) error = 'Password minimal 6 karakter';
    else if (pass != confirm) error = 'Konfirmasi password tidak sama';

    if (error != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final cred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: pass);

      // set display name
      await cred.user?.updateDisplayName(username);

      // kirim email verifikasi (pakai bahasa Indonesia; tanpa ACS agar sederhana & aman)
      try {
        await FirebaseAuth.instance.setLanguageCode('id');
        await cred.user?.sendEmailVerification();
      } on FirebaseAuthException catch (e) {
        if (mounted) {
          final msg = e.code == 'too-many-requests'
              ? 'Terlalu banyak permintaan dari perangkat ini. Coba lagi beberapa menit.'
              : (e.message ?? 'Gagal mengirim email verifikasi');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg)),
          );
        }
      } catch (_) {}

      if (!mounted) return;
      // Tampilkan modal verifikasi agar user bisa resend & cek status
      // Jangan langsung ke login—tahan di modal hingga verified
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: StatefulBuilder(
              builder: (ctx, setStateSheet) {
                bool _sheetAlive = true;
                int resendCooldown = 0; // detik
                Timer? cooldownTimer;
                void startCooldown(int seconds) {
                  resendCooldown = seconds;
                  if (ctx.mounted && _sheetAlive) setStateSheet(() {});
                  cooldownTimer?.cancel();
                  cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
                    if (!ctx.mounted || !_sheetAlive) {
                      t.cancel();
                      return;
                    }
                    if (resendCooldown <= 1) {
                      t.cancel();
                      resendCooldown = 0;
                    } else {
                      resendCooldown -= 1;
                    }
                    if (ctx.mounted && _sheetAlive) setStateSheet(() {});
                  });
                }
                bool localLoading = false;
                final emailShown = FirebaseAuth.instance.currentUser?.email ?? email;
                return WillPopScope(
                  onWillPop: () async {
                    cooldownTimer?.cancel();
                    _sheetAlive = false;
                    return true;
                  },
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: DraggableScrollableSheet(
                        expand: false,
                        initialChildSize: 0.3,
                        minChildSize: 0.2,
                        maxChildSize: 0.6,
                        builder: (context, scrollController) {
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.30),
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.35),
                                width: 1,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                            child: SingleChildScrollView(
                              controller: scrollController,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Center(
                                    child: SizedBox(
                                      width: 40,
                                      child: Divider(thickness: 4),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Verifikasi Email',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Kami mengirim email verifikasi ke:\n$emailShown',
                                    style: const TextStyle(color: Colors.white70),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(20),
                                          child: BackdropFilter(
                                            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(0.25),
                                                borderRadius: BorderRadius.circular(20),
                                                border: Border.all(color: Colors.white.withOpacity(0.3)),
                                              ),
                                              child: TextButton(
                                                onPressed: (localLoading || resendCooldown > 0) ? null : () async {
                                                  if (FirebaseAuth.instance.currentUser != null &&
                                                      !(FirebaseAuth.instance.currentUser!.emailVerified)) {
                                                    try {
                                                      if (ctx.mounted && _sheetAlive) setStateSheet(() => localLoading = true);
                                                      await FirebaseAuth.instance.setLanguageCode('id');
                                                      await FirebaseAuth.instance.currentUser!.sendEmailVerification();
                                                      if (mounted) {
                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                          const SnackBar(content: Text('Email verifikasi dikirim ulang')),
                                                        );
                                                      }
                                                      startCooldown(60);
                                                    } on FirebaseAuthException catch (e) {
                                                      final msg = e.code == 'too-many-requests'
                                                          ? 'Terlalu banyak permintaan dari perangkat ini. Coba lagi beberapa menit.'
                                                          : (e.message ?? 'Gagal mengirim email verifikasi');
                                                      if (mounted) {
                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                          SnackBar(content: Text(msg)),
                                                        );
                                                      }
                                                      startCooldown(90);
                                                    } finally {
                                                      if (ctx.mounted && _sheetAlive) setStateSheet(() => localLoading = false);
                                                    }
                                                  }
                                                },
                                                child: localLoading
                                                    ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                                    : Text(
                                                        resendCooldown > 0 ? 'Kirim Ulang (${resendCooldown}s)' : 'Kirim Ulang',
                                                        style: const TextStyle(color: Colors.black),
                                                      ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(20),
                                          child: BackdropFilter(
                                            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(0.25),
                                                borderRadius: BorderRadius.circular(20),
                                                border: Border.all(color: Colors.white.withOpacity(0.3)),
                                              ),
                                              child: TextButton(
                                                onPressed: localLoading ? null : () async {
                                                  await FirebaseAuth.instance.currentUser?.reload();
                                                  final refreshed = FirebaseAuth.instance.currentUser;
                                                  if (refreshed?.emailVerified == true) {
                                                    cooldownTimer?.cancel();
                                                    _sheetAlive = false;
                                                    if (Navigator.of(ctx).canPop()) Navigator.of(ctx).pop();
                                                    widget.onLoginTap();
                                                  } else {
                                                    if (mounted) {
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        const SnackBar(content: Text('Belum terverifikasi. Cek email & klik tautannya.')),
                                                      );
                                                    }
                                                  }
                                                },
                                                child: const Text(
                                                  'Saya Sudah Verifikasi',
                                                  style: TextStyle(color: Colors.black),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  const SizedBox(height: 16),
                                  const Text('Tips: cek folder Spam/Promotions jika belum masuk.', style: TextStyle(color: Colors.white70)),
                                  const SizedBox(height: 8),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      );
    } on FirebaseAuthException catch (e) {
      String msg = 'Gagal membuat akun';
      switch (e.code) {
        case 'email-already-in-use':
          msg = 'Email sudah terdaftar';
          break;
        case 'invalid-email':
          msg = 'Email tidak valid';
          break;
        case 'weak-password':
          msg = 'Password terlalu lemah';
          break;
        case 'operation-not-allowed':
          msg = 'Metode email/password belum diaktifkan di Firebase Console';
          break;
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF007BC1), Color(0xFF6EC6FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
              children: [
                const SizedBox(height:76),
                Image.asset(
                  'lib/app/assets/images/cvm.png',
                  height: 120,
                ),
                const SizedBox(height: 10),
                const Text(
                  "CIPTA VERA MANDIRI\nDIGITAL",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    color: Colors.white,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 10),
                // Username
                _buildTextField("Username", Icons.person, widget.usernameController),
                const SizedBox(height: 10),
                // Email
                _buildTextField("Email", Icons.email, widget.emailController),
                const SizedBox(height: 10),
                // Password
                _buildPasswordField(),
                const SizedBox(height: 10),
                // Confirm Password
                _buildConfirmPasswordField(),
                const SizedBox(height: 61),
                // Tombol Sign Up
                ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      width: 220,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.32),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.5),
                          width: 1.2,
                        ),
                      ),
                      child: TextButton(
                        onPressed: _loading ? null : _handleSignup,
                        child: _loading
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text(
                                "Sign Up",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                // Kembali ke Login
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Already have an account? ",
                      style: TextStyle(color: Colors.white),
                    ),
                    GestureDetector(
                      onTap: widget.onLoginTap,
                      child: const Text(
                        "Login",
                        style: TextStyle(
                          color: Color.fromARGB(255, 11, 47, 110),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 50),
                // Login with Google
                const Text(
                  "Login with :",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(50),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      width: 180,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.62),
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(
                          color: Colors.grey.withOpacity(0.4),
                          width: 1.2,
                        ),
                      ),
                      child: TextButton(
                        style: TextButton.styleFrom(
                          elevation: 0,
                        ),
                        onPressed: () {
                          // Tambahkan logika login Google di sini jika diperlukan
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'lib/app/assets/images/goggle.png', // pastikan nama file benar
                              height: 24,
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              "Google",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String hint, IconData icon, TextEditingController ctrl) {
    return TextField(
      controller: ctrl,
      keyboardType: hint.toLowerCase() == 'email' ? TextInputType.emailAddress : TextInputType.text,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white.withOpacity(0.2),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.white),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return TextField(
      controller: widget.passwordController,
      obscureText: _obscurePassword,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white.withOpacity(0.2),
        hintText: "Password",
        hintStyle: const TextStyle(color: Colors.white70),
        prefixIcon: const Icon(Icons.lock, color: Colors.white),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
            color: Colors.white,
          ),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
  Widget _buildConfirmPasswordField() {
    return TextField(
      controller: widget.confirmPasswordController,
      obscureText: _obscurePassword,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white.withOpacity(0.2),
        hintText: "Confirm Password",
        hintStyle: const TextStyle(color: Colors.white70),
        prefixIcon: const Icon(Icons.lock, color: Colors.white),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
            color: Colors.white,
          ),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}