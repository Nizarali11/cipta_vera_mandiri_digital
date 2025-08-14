import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';

class LoginController extends GetxController {
  // Form field controller
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  // Loading state
  var isLoading = false.obs;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Function login
  void login() async {
    String email = emailController.text.trim();
    String password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      Get.snackbar("Error", "Email & Password tidak boleh kosong");
      return;
    }

    isLoading.value = true;

    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      Get.snackbar("Sukses", "Login berhasil");
      Get.offAllNamed('/home');
    } on FirebaseAuthException catch (e) {
      String message = "";
      if (e.code == 'user-not-found') {
        message = "Pengguna tidak ditemukan";
      } else if (e.code == 'wrong-password') {
        message = "Password salah";
      } else {
        message = e.message ?? "Terjadi kesalahan";
      }
      Get.snackbar("Error", message);
    } catch (e) {
      Get.snackbar("Error", "Terjadi kesalahan: $e");
    } finally {
      isLoading.value = false;
    }
  }
}