import 'package:cipta_vera_mandiri_digital/app/modules/home/views/home_view.dart';
import 'package:cipta_vera_mandiri_digital/app/modules/pages/calendar_page.dart';
import 'package:cipta_vera_mandiri_digital/app/modules/pages/chat_page.dart';
import 'package:cipta_vera_mandiri_digital/app/modules/pages/profile_page.dart';
import 'package:cipta_vera_mandiri_digital/app/modules/pages/settings_page.dart';
import 'package:cipta_vera_mandiri_digital/app/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
  final List<Widget> _pages = const [
    HomeView(),
    ChatPage(),
    CalendarPage(),
    ProfilePage(),
    SettingsPage(),
  ];

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

  void _login() {
    const dummyUsername = 'admin';
    const dummyPassword = '123456';

    if (loginUsernameController.text.isEmpty || loginPasswordController.text.isEmpty) {
      Get.snackbar('Login Gagal', 'Username dan password wajib diisi',
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    if (loginUsernameController.text == dummyUsername &&
        loginPasswordController.text == dummyPassword) {
      Get.offAllNamed(Routes.HOME);
    } else {
      Get.snackbar('Login Gagal', 'Username atau password salah',
          backgroundColor: Colors.red, colorText: Colors.white);
    }
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