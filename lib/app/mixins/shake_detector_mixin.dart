import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// 가속도계 기반 흔들기 감지 mixin.
/// Design Ref: §2.2 — 토글 ON일 때만 subscribe해 배터리 영향을 최소화.
///
/// [enableShakeDetection]에 콜백을 전달하면 임계값을 넘는 흔들림이
/// 디바운스 간격을 두고 감지될 때마다 호출된다.
mixin ShakeDetectorMixin on GetxController {
  StreamSubscription<UserAccelerometerEvent>? _shakeSub;
  DateTime? _lastShakeAt;

  /// 흔들기 임계값 (m/s²). 일상 동작과 흔들기를 구분하기 위해 보수적으로 설정.
  static const double shakeThreshold = 25.0;

  /// 최소 디바운스 간격. 한 번 감지 후 이 시간 이내에는 무시.
  static const Duration shakeDebounce = Duration(milliseconds: 800);

  /// 테스트 주입용 stream factory. 기본은 sensors_plus의 글로벌 stream.
  @visibleForTesting
  Stream<UserAccelerometerEvent> Function()? shakeStreamFactoryForTest;

  bool get isShakeDetectionActive => _shakeSub != null;

  void enableShakeDetection(VoidCallback onShake) {
    _shakeSub?.cancel();
    final factory =
        shakeStreamFactoryForTest ?? () => userAccelerometerEventStream();
    _shakeSub = factory().listen((event) {
      final magnitude = math.sqrt(
        event.x * event.x + event.y * event.y + event.z * event.z,
      );
      if (magnitude < shakeThreshold) return;

      final now = DateTime.now();
      final last = _lastShakeAt;
      if (last != null && now.difference(last) < shakeDebounce) return;

      _lastShakeAt = now;
      onShake();
    });
  }

  void disableShakeDetection() {
    _shakeSub?.cancel();
    _shakeSub = null;
    _lastShakeAt = null;
  }

  @override
  void onClose() {
    disableShakeDetection();
    super.onClose();
  }
}
