// ignore_for_file: constant_identifier_names

import 'package:get/get.dart';

import 'package:doodle_pad/app/bindings/app_binding.dart';
import 'package:doodle_pad/app/pages/home/home_page.dart';
import 'package:doodle_pad/app/pages/draw/draw_page.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const INITIAL = Routes.HOME;

  static final routes = [
    GetPage(
      name: _Paths.HOME,
      page: () => const HomePage(),
      binding: AppBinding(),
    ),
    GetPage(
      name: _Paths.DRAW,
      page: () => const DrawPage(),
    ),
  ];
}
