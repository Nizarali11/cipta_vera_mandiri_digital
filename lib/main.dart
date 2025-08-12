import 'package:cipta_vera_mandiri_digital/app/modules/home/controllers/home_controller.dart';
import 'package:cipta_vera_mandiri_digital/app/modules/home/views/auth_view.dart';
import 'package:cipta_vera_mandiri_digital/app/modules/home/views/home_view.dart';
import 'package:cipta_vera_mandiri_digital/app/modules/home/views/login_view.dart';
import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'app/routes/app_pages.dart';



void main() {
  Get.put(HomeController());
  bool isLoggedIn = false; // nanti diganti cek autentikasi

  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  
  runApp(
    GetMaterialApp(
      debugShowCheckedModeBanner: false,
      home: isLoggedIn 
        // ignore: dead_code
        ? const AuthView() 
        : LoginView(
            usernameController: usernameController,
            passwordController: passwordController,
            onSignUpTap: () {
              Get.toNamed('/signup');
            },
            onLoginSuccess: () {
              Get.offAll(() => const HomeView());
            },
          ),
      getPages: AppPages.routes,
    ),
  );
  
}
