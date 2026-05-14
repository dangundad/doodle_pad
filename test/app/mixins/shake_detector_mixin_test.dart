import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:sensors_plus/sensors_plus.dart';

import 'package:doodle_pad/app/mixins/shake_detector_mixin.dart';

class _TestController extends GetxController with ShakeDetectorMixin {}

UserAccelerometerEvent _event(double x, double y, double z) {
  return UserAccelerometerEvent(x, y, z, DateTime.now());
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _TestController controller;
  late StreamController<UserAccelerometerEvent> stream;

  setUp(() {
    Get.testMode = true;
    controller = _TestController();
    stream = StreamController<UserAccelerometerEvent>.broadcast();
    controller.shakeStreamFactoryForTest = () => stream.stream;
  });

  tearDown(() async {
    controller.disableShakeDetection();
    await stream.close();
    Get.reset();
  });

  test('임계값 이상 흔들림 → 콜백 1회', () async {
    var calls = 0;
    controller.enableShakeDetection(() => calls += 1);

    stream.add(_event(20, 0, 0)); // magnitude=20, 임계값(25) 미만
    await Future<void>.delayed(Duration.zero);
    expect(calls, 0);

    stream.add(_event(20, 20, 10)); // magnitude≈30, 초과
    await Future<void>.delayed(Duration.zero);
    expect(calls, 1);
  });

  test('디바운스: 800ms 내 두 번째 흔들림은 무시', () async {
    var calls = 0;
    controller.enableShakeDetection(() => calls += 1);

    stream.add(_event(20, 20, 10));
    await Future<void>.delayed(Duration.zero);
    stream.add(_event(20, 20, 10));
    await Future<void>.delayed(Duration.zero);

    expect(calls, 1, reason: '디바운스 800ms 안이라 한 번만 트리거');
  });

  test('disableShakeDetection: 이후 이벤트는 무시', () async {
    var calls = 0;
    controller.enableShakeDetection(() => calls += 1);
    controller.disableShakeDetection();

    stream.add(_event(20, 20, 10));
    await Future<void>.delayed(Duration.zero);
    expect(calls, 0);
    expect(controller.isShakeDetectionActive, false);
  });

  test('enable 두 번 호출: 기존 구독 해제 후 새로 구독', () async {
    var calls = 0;
    controller.enableShakeDetection(() => calls += 100);
    controller.enableShakeDetection(() => calls += 1);

    stream.add(_event(20, 20, 10));
    await Future<void>.delayed(Duration.zero);
    expect(calls, 1, reason: '두 번째 콜백만 호출되어야 한다');
  });
}
