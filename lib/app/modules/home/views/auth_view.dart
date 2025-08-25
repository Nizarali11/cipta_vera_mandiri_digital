import 'package:cipta_vera_mandiri_digital/app/modules/home/views/home_view.dart';
import 'package:cipta_vera_mandiri_digital/app/modules/pages/calendar_page.dart';
import 'package:cipta_vera_mandiri_digital/app/modules/pages/chat_list_page.dart';
import 'package:cipta_vera_mandiri_digital/app/modules/home/chat/chat_page.dart';
import 'package:cipta_vera_mandiri_digital/app/modules/pages/profile_page.dart';
import 'package:cipta_vera_mandiri_digital/app/modules/pages/settings_page.dart';
import 'package:cipta_vera_mandiri_digital/app/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'login_view.dart' as my_views;
import 'signup_view.dart' as my_views;

class AuthView extends StatefulWidget {
  const AuthView({super.key});

  @override
  State<AuthView> createState() => _AuthViewState();
}

class _AuthViewState extends State<AuthView> {
  bool showLogin = true;
  // ignore: unused_field
  int _selectedIndex = 0;

  // ignore: unused_field
  late final List<Widget> _pages;

  // Controller untuk login
  final loginUsernameController = TextEditingController();
  final loginPasswordController = TextEditingController();

  // Controller untuk signup
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  void _goToSignup() => setState(() => showLogin = false);

  void _goToLogin() => setState(() => showLogin = true);

  Future<void> _login() async {
    if (loginUsernameController.text.isEmpty || loginPasswordController.text.isEmpty) {
      Get.snackbar('Login Gagal', 'Email dan password wajib diisi',
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    try {
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: loginUsernameController.text.trim(),
        password: loginPasswordController.text.trim(),
      );

      if (!userCredential.user!.emailVerified) {
        await userCredential.user!.sendEmailVerification();
        Get.snackbar('Email Belum Diverifikasi',
            'Kami sudah kirim ulang link verifikasi ke email Anda.',
            backgroundColor: Colors.orange, colorText: Colors.white);
        return;
      }

      // Cek apakah profil sudah dilengkapi; jika belum, arahkan ke halaman lengkapi profil (sekali saja)
      try {
        final uid = userCredential.user!.uid;
        final snap = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get();
        final completed = snap.data()?['profileCompleted'] == true || snap.data()?['isComplete'] == true;
        if (!completed) {
          Get.offAllNamed('/complete-profile');
          return;
        }
      } catch (e) {
        // Jika gagal baca Firestore, tetap lanjut ke HOME agar tidak menghambat login
      }

      Get.offAllNamed(Routes.HOME);
    } on FirebaseAuthException catch (e) {
      String msg = 'Terjadi kesalahan';
      if (e.code == 'user-not-found') {
        msg = 'Pengguna tidak ditemukan';
      } else if (e.code == 'wrong-password') {
        msg = 'Password salah';
      }
      Get.snackbar('Login Gagal', msg,
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  @override
  void initState() {
    super.initState();
    _pages = [
      HomeView(
        onMenuSelected: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        onLogout: () {
          setState(() {
            showLogin = true;
          });
        },
      ),
      const ChatListPage(),
      const CalendarPage(),
      const ProfilePage(),
      const SettingsPage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF007BC1), Color(0xFF6EC6FF)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: showLogin
            ? my_views.LoginView(
                key: const ValueKey('login'),
                usernameController: loginUsernameController,
                passwordController: loginPasswordController,
                onSignUpTap: _goToSignup,
                onLoginSuccess: _login,
              )
            : my_views.SignupView(
                key: const ValueKey('signup'),
                onLoginTap: _goToLogin,
                usernameController: usernameController,
                emailController: emailController,
                passwordController: passwordController,
                confirmPasswordController: confirmPasswordController,
                onSignupTap: () {
                  // aksi signup sukses
                  _goToLogin();
                },
              ),
      ),
    );
  }
}