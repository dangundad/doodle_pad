import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:perfect_freehand/perfect_freehand.dart' as pf;

import 'package:doodle_pad/app/controllers/doodle_controller.dart';
import 'package:doodle_pad/app/data/brushes/brush_preset.dart';

/// 모든 브러시 정의의 단일 출처.
///
/// eraser는 BlendMode.clear가 outline polygon이 아닌 path 직접 처리에
/// 더 적합하므로 [_registry]에 포함하지 않고 CanvasPainter에서 분기 처리한다.
///
/// 신규 brush 추가는 [_registry]에 항목 1개를 더하는 것으로 끝난다.
class BrushPresets {
  BrushPresets._();

  /// 모든 brush의 굵기/감도/잠금/후처리 정의가 모인 단일 표.
  static final Map<BrushType, BrushPreset> _registry = {
    BrushType.pen: BrushPreset(
      type: BrushType.pen,
      labelKey: 'brush_pen',
      icon: LucideIcons.pen,
      sizeMultiplier: 1.0,
      optionsBuilder: (s) => pf.StrokeOptions(
        size: s,
        thinning: 0.0,
        smoothing: 0.5,
        streamline: 0.5,
        simulatePressure: false,
      ),
    ),
    BrushType.pencil: BrushPreset(
      type: BrushType.pencil,
      labelKey: 'brush_pencil',
      icon: LucideIcons.pencil,
      sizeMultiplier: 0.7,
      optionsBuilder: (s) => pf.StrokeOptions(
        size: s,
        thinning: 0.6,
        smoothing: 0.4,
        streamline: 0.5,
        simulatePressure: true,
      ),
      alpha: 0.85,
      postProcess: BrushPostProcess.crayonNoise,
    ),
    BrushType.marker: BrushPreset(
      type: BrushType.marker,
      labelKey: 'brush_marker',
      icon: LucideIcons.brush,
      sizeMultiplier: 2.0,
      optionsBuilder: (s) => pf.StrokeOptions(
        size: s,
        thinning: 0.0,
        smoothing: 0.5,
        streamline: 0.5,
        simulatePressure: false,
      ),
    ),
    BrushType.brush: BrushPreset(
      type: BrushType.brush,
      labelKey: 'brush_brush',
      icon: LucideIcons.paintbrush,
      sizeMultiplier: 1.5,
      optionsBuilder: (s) => pf.StrokeOptions(
        size: s,
        thinning: 0.7,
        smoothing: 0.6,
        streamline: 0.6,
        simulatePressure: true,
      ),
    ),
    BrushType.highlighter: BrushPreset(
      type: BrushType.highlighter,
      labelKey: 'brush_highlighter',
      icon: LucideIcons.highlighter,
      sizeMultiplier: 2.4,
      optionsBuilder: (s) => pf.StrokeOptions(
        size: s,
        thinning: 0.0,
        smoothing: 0.5,
        streamline: 0.5,
        simulatePressure: false,
      ),
      alpha: 0.35,
    ),
    BrushType.fountainPen: BrushPreset(
      type: BrushType.fountainPen,
      labelKey: 'brush_fountain_pen',
      icon: LucideIcons.feather,
      sizeMultiplier: 1.0,
      optionsBuilder: (s) => pf.StrokeOptions(
        size: s,
        thinning: 0.85,
        smoothing: 0.6,
        streamline: 0.7,
        simulatePressure: true,
      ),
    ),
    BrushType.crayon: BrushPreset(
      type: BrushType.crayon,
      labelKey: 'brush_crayon',
      icon: LucideIcons.palette,
      sizeMultiplier: 1.4,
      optionsBuilder: (s) => pf.StrokeOptions(
        size: s,
        thinning: 0.4,
        smoothing: 0.4,
        streamline: 0.3,
        simulatePressure: true,
      ),
      alpha: 0.85,
      postProcess: BrushPostProcess.crayonNoise,
    ),
    BrushType.watercolor: BrushPreset(
      type: BrushType.watercolor,
      labelKey: 'watercolor_brush',
      icon: LucideIcons.droplet,
      sizeMultiplier: 1.6,
      optionsBuilder: (s) => pf.StrokeOptions(
        size: s,
        thinning: 0.3,
        smoothing: 0.7,
        streamline: 0.7,
        simulatePressure: true,
      ),
      alpha: 0.28,
      postProcess: BrushPostProcess.watercolorBlur,
      lock: BrushLock.watercolor,
    ),
    BrushType.airbrush: BrushPreset(
      type: BrushType.airbrush,
      labelKey: 'airbrush_brush',
      icon: LucideIcons.sprayCan,
      sizeMultiplier: 1.0,
      // airbrush는 outline이 아닌 점 분포라 optionsBuilder는 호출되지 않지만,
      // 인터페이스 일관성을 위해 size만 채워둔다.
      optionsBuilder: (s) => pf.StrokeOptions(size: s),
      postProcess: BrushPostProcess.airbrushSpray,
      lock: BrushLock.airbrush,
    ),
  };

  /// 등록된 brush 정의 반환. eraser 호출 시 null.
  static BrushPreset? maybeOf(BrushType t) => _registry[t];

  /// 등록되지 않은 brush 호출 시 throw.
  static BrushPreset of(BrushType t) {
    final preset = _registry[t];
    if (preset == null) {
      throw StateError('No BrushPreset registered for $t');
    }
    return preset;
  }

  /// 셀렉터 표시 순서대로 (eraser는 별도 셀로 추가).
  static List<BrushPreset> get values => _registry.values.toList();
}
