import 'package:cipta_vera_mandiri_digital/app/modules/home/bindings/home_binding.dart';
import 'package:cipta_vera_mandiri_digital/app/modules/home/views/auth_view.dart';
import 'package:cipta_vera_mandiri_digital/app/modules/pages/homepage.dart';
import 'package:get/get.dart';

import '../modules/home/bindings/login_binding.dart';
import '../modules/home/views/home_view.dart';

import 'app_routes.dart';

class AppPages {
  static final routes = [
    GetPage(
      name: Routes.LOGIN,
      page: () => const AuthView(),
      binding: LoginBinding(),
    ),
    GetPage(
      name: Routes.HOME,
      page: () => HomePage(),
        binding: HomeBinding(),
    ),
  ];
}