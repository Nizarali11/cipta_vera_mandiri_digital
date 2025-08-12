import 'package:cipta_vera_mandiri_digital/app/modules/home/controllers/home_controller.dart';
import 'package:cipta_vera_mandiri_digital/app/modules/home/views/auth_view.dart';
import 'package:cipta_vera_mandiri_digital/app/modules/home/views/login_view.dart';
import 'package:cipta_vera_mandiri_digital/app/routes/app_routes.dart';
import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:cipta_vera_mandiri_digital/app/modules/pages/homepage.dart';
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
