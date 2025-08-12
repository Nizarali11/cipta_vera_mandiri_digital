import 'package:cipta_vera_mandiri_digital/app/modules/home/views/home_view.dart';
import 'package:cipta_vera_mandiri_digital/app/modules/pages/calendar_page.dart';
import 'package:cipta_vera_mandiri_digital/app/modules/pages/chat_page.dart';
import 'package:cipta_vera_mandiri_digital/app/modules/pages/profile_page.dart';
import 'package:cipta_vera_mandiri_digital/app/modules/pages/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'login_view.dart' as my_views;

class AuthView extends StatefulWidget {
  const AuthView({super.key});

  @override
  State<AuthView> createState() => _AuthViewState();
}

class _AuthViewState extends State<AuthView> {
  bool showLogin = true;
  int _selectedIndex = 0;

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

  void _goToSignup() => setState(() => showLogin = false);

  void _login() {
    const dummyUsername = 'admin';
    const dummyPassword = '123456';

    if (loginUsernameController.text == dummyUsername &&
        loginPasswordController.text == dummyPassword) {
      setState(() {
        showLogin = false;
        _selectedIndex = 0;
      });
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
            : Scaffold(
                backgroundColor: Colors.transparent,
                body: IndexedStack(
                  index: _selectedIndex,
                  children: _pages,
                ),
                bottomNavigationBar: BottomNavigationBar(
                  currentIndex: _selectedIndex,
                  onTap: (index) {
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                  type: BottomNavigationBarType.fixed,
                  items: const [
                    BottomNavigationBarItem(
                      icon: Icon(Icons.home),
                      label: 'Home',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.chat),
                      label: 'Chat',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.calendar_today),
                      label: 'Calendar',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.person),
                      label: 'Profile',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.settings),
                      label: 'Settings',
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}