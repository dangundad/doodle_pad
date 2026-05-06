// ignore_for_file: constant_identifier_names

part of 'app_pages.dart';

abstract class Routes {
  Routes._();

  static const HOME = _Paths.HOME;
  static const PREMIUM = _Paths.PREMIUM;
  static const DRAW = _Paths.DRAW;
  static const SETTINGS = _Paths.SETTINGS;
}

abstract class _Paths {
  static const HOME = '/home';
  static const PREMIUM = '/premium';
  static const DRAW = '/draw';
  static const SETTINGS = '/settings';
}
