// ignore_for_file: constant_identifier_names

import 'package:get/get.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

import 'package:doodle_pad/app/data/models/drawing.dart';
import 'package:doodle_pad/hive_registrar.g.dart';

class HiveService extends GetxService {
  static HiveService get to => Get.find();

  // Box 이름 상수
  static const String SETTINGS_BOX = 'settings';
  static const String APP_DATA_BOX = 'app_data';
  // Design Ref: §3.3 — 작품 영속화용 typed box.
  static const String DRAWINGS_BOX = 'drawings';

  // Box Getters
  Box get settingsBox => Hive.box(SETTINGS_BOX);
  Box get appDataBox => Hive.box(APP_DATA_BOX);
  Box<Drawing> get drawingsBox => Hive.box<Drawing>(DRAWINGS_BOX);

  /// Hive 초기화 (main.dart에서 await 호출)
  static Future<void> init() async {
    await Hive.initFlutter();
    // Design Ref: §3.3 — openBox 호출 전에 모든 adapter를 등록한다.
    Hive.registerAdapters();

    await Future.wait([
      Hive.openBox(SETTINGS_BOX),
      Hive.openBox(APP_DATA_BOX),
      Hive.openBox<Drawing>(DRAWINGS_BOX),
    ]);

    Get.log('Hive 초기화 완료');
  }

  // ============================================
  // 설정 관리 (generic key-value)
  // ============================================

  T? getSetting<T>(String key, {T? defaultValue}) {
    return settingsBox.get(key, defaultValue: defaultValue) as T?;
  }

  Future<void> setSetting(String key, dynamic value) async {
    await settingsBox.put(key, value);
  }

  // ============================================
  // 앱 데이터 관리 (generic key-value)
  // ============================================

  T? getAppData<T>(String key, {T? defaultValue}) {
    return appDataBox.get(key, defaultValue: defaultValue) as T?;
  }

  Future<void> setAppData(String key, dynamic value) async {
    await appDataBox.put(key, value);
  }

  // ============================================
  // 앱별 데이터 CRUD 추가
  // ============================================
  // 캐싱 패턴 예시:
  //
  // List<MyModel>? _cache;
  //
  // void _invalidateCache() { _cache = null; }
  //
  // List<MyModel> getAllItems({bool forceRefresh = false}) {
  //   if (!forceRefresh && _cache != null) return List.from(_cache!);
  //   final items = myModelBox.values.toList();
  //   _cache = items;
  //   return List.from(items);
  // }
  //
  // Future<void> addItem(MyModel item) async {
  //   await myModelBox.put(item.id, item);
  //   _invalidateCache();
  // }

  // ============================================
  // 데이터 관리
  // ============================================

  Future<void> clearAllData() async {
    await Future.wait([settingsBox.clear(), appDataBox.clear()]);
    Get.log('모든 데이터 삭제 완료');
  }
}
