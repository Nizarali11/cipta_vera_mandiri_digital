import 'package:get/get.dart';
import 'package:flutter/material.dart';

class SignupController extends GetxController {
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  var isLoading = false.obs;

  void signup() async {
    if (usernameController.text.isEmpty ||
        emailController.text.isEmpty ||
        passwordController.text.isEmpty) {
      Get.snackbar("Error", "Semua field wajib diisi");
      return;
    }

    isLoading.value = true;
    await Future.delayed(const Duration(seconds: 2)); // simulasi API

    Get.snackbar("Sukses", "Akun berhasil dibuat");
    Get.offAllNamed('/login');

    isLoading.value = false;
  }
}