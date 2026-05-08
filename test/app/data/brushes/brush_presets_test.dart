import 'package:flutter_test/flutter_test.dart';

import 'package:doodle_pad/app/controllers/doodle_controller.dart';
import 'package:doodle_pad/app/data/brushes/brush_preset.dart';
import 'package:doodle_pad/app/data/brushes/brush_presets.dart';

void main() {
  group('BrushPresets registry', () {
    test('every BrushType except eraser is registered', () {
      for (final t in BrushType.values) {
        if (t == BrushType.eraser) {
          expect(BrushPresets.maybeOf(t), isNull,
              reason: 'eraser must NOT be in registry');
          continue;
        }
        expect(BrushPresets.maybeOf(t), isNotNull,
            reason: '$t must be registered');
      }
    });

    test('of(eraser) throws StateError', () {
      expect(() => BrushPresets.of(BrushType.eraser), throwsA(isA<StateError>()));
    });

    test('values list has correct length (BrushType.values - 1 eraser)', () {
      expect(BrushPresets.values.length, BrushType.values.length - 1);
    });

    test('optionsBuilder produces positive size for slider range 2..30', () {
      for (final preset in BrushPresets.values) {
        for (final s in [2.0, 6.0, 15.0, 30.0]) {
          final opts = preset.optionsBuilder(s);
          expect(opts.size, greaterThan(0),
              reason: '${preset.type} at base=$s produced non-positive size');
        }
      }
    });

    test('lock mapping matches existing Hive asset assignment', () {
      expect(BrushPresets.of(BrushType.watercolor).lock, BrushLock.watercolor);
      expect(BrushPresets.of(BrushType.airbrush).lock, BrushLock.airbrush);
      expect(BrushPresets.of(BrushType.pen).lock, BrushLock.none);
      expect(BrushPresets.of(BrushType.crayon).lock, BrushLock.none);
      expect(BrushPresets.of(BrushType.fountainPen).lock, BrushLock.none);
    });

    test('alpha is within 0..1 range', () {
      for (final preset in BrushPresets.values) {
        expect(preset.alpha, inInclusiveRange(0.0, 1.0),
            reason: '${preset.type} alpha out of range');
      }
    });

    test('every preset has a non-empty translate label key', () {
      for (final preset in BrushPresets.values) {
        expect(preset.labelKey, isNotEmpty);
        expect(preset.labelKey, matches(r'^[a-z_]+$'),
            reason: '${preset.type} labelKey should be snake_case');
      }
    });
  });
}
