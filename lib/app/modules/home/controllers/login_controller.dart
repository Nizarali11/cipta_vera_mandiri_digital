import 'package:get/get.dart';
import 'package:flutter/material.dart';

class LoginController extends GetxController {
  // Form field controller
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  // Loading state
  var isLoading = false.obs;

  // Function login
  void login() async {
    String email = emailController.text;
    String password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      Get.snackbar("Error", "Email & Password tidak boleh kosong");
      return;
    }

    isLoading.value = true;

    await Future.delayed(Duration(seconds: 2)); // simulasi API

    if (email == "admin@gmail.com" && password == "123456") {
      Get.snackbar("Sukses", "Login berhasil");
      // Pindah halaman setelah login
      Get.offAllNamed('/home');
    } else {
      Get.snackbar("Error", "Email atau Password salah");
    }

    isLoading.value = false;
  }
}