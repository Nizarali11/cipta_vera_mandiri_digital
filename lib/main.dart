import 'package:cipta_vera_mandiri_digital/app/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'app/routes/app_pages.dart';



void main() {
   runApp(
    GetMaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: Routes.LOGIN,   // Mulai dari halaman login
      getPages: AppPages.routes,    // Daftar route yang sudah kamu definisikan
    ),
  );
}
