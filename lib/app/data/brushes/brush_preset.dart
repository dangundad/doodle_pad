import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:perfect_freehand/perfect_freehand.dart' as pf;

import 'package:doodle_pad/app/controllers/doodle_controller.dart';

/// 브러시별 stroke 옵션과 후처리 정보를 담는 데이터 객체.
///
/// CanvasPainter는 BrushType 분기 대신 [BrushPreset.render] 호출 한 번으로
/// 모든 brush를 그린다. 신규 brush 추가 시 [BrushPresets._registry]에 항목
/// 1개를 더하면 된다.
class BrushPreset {
  /// brush 식별자.
  final BrushType type;

  /// translate.dart 키 (예: `brush_pen`, `watercolor_brush`).
  final String labelKey;

  /// 셀렉터 아이콘.
  final IconData icon;

  /// stroke 슬라이더 값(이미 [sizeMultiplier] 적용된 effectiveSize)을 받아
  /// perfect_freehand StrokeOptions를 생성한다.
  ///
  /// 외부 호출자는 항상 `optionsBuilder(stroke.width * sizeMultiplier)` 형태로
  /// 호출하므로 builder 내부에서는 추가 곱연산을 하지 않는다.
  final pf.StrokeOptions Function(double effectiveSize) optionsBuilder;

  /// 후처리 종류.
  final BrushPostProcess postProcess;

  /// 0~1. paint alpha. 1.0=불투명, 0.35=형광펜.
  final double alpha;

  /// 사용자 슬라이더 값(`stroke.width`)에 곱하는 brush별 굵기 배율.
  /// 예: marker=2.0, highlighter=2.4, pencil=0.7. 1.0이면 원본 그대로.
  final double sizeMultiplier;

  /// 잠금 카테고리.
  final BrushLock lock;

  const BrushPreset({
    required this.type,
    required this.labelKey,
    required this.icon,
    required this.optionsBuilder,
    this.postProcess = BrushPostProcess.none,
    this.alpha = 1.0,
    this.sizeMultiplier = 1.0,
    this.lock = BrushLock.none,
  });

  /// stroke 슬라이더 값에 sizeMultiplier를 곱한 effective size.
  double effectiveSize(DrawingStroke stroke) => stroke.width * sizeMultiplier;

  /// stroke 1개를 [canvas]에 그린다.
  ///
  /// - airbrush는 outline polygon이 아닌 점 분포라 자체 분기.
  /// - 그 외는 perfect_freehand outline → fill path.
  /// - watercolor는 outline 위에 추가 blur layer.
  /// - crayon/pencil은 outline 위에 noise grain dot.
  void render(ui.Canvas canvas, DrawingStroke stroke) {
    if (stroke.points.isEmpty) return;

    final size = effectiveSize(stroke);

    if (postProcess == BrushPostProcess.airbrushSpray) {
      _drawAirbrushSpray(canvas, stroke, size);
      return;
    }

    final basePaint = Paint()
      ..color = stroke.color.withValues(alpha: alpha)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true
      ..blendMode = BlendMode.srcOver;

    // 단일 점은 outline polygon이 거의 빈 결과라 별도 dot 처리.
    if (stroke.points.length == 1) {
      final r = math.max(size / 2, 1.0);
      canvas.drawCircle(stroke.points.first, r, basePaint);
      _applyPostProcess(canvas, stroke, basePaint, size, isDot: true);
      return;
    }

    final outline = pf.getStroke(
      stroke.points
          .map((p) => pf.PointVector(p.dx, p.dy))
          .toList(growable: false),
      options: optionsBuilder(size),
    );

    if (outline.isEmpty) {
      // perfect_freehand가 빈 outline을 돌려주는 경계 케이스: 직선 fallback.
      final fallback = Path()
        ..moveTo(stroke.points.first.dx, stroke.points.first.dy);
      for (var i = 1; i < stroke.points.length; i++) {
        fallback.lineTo(stroke.points[i].dx, stroke.points[i].dy);
      }
      final strokePaint = Paint()
        ..color = stroke.color.withValues(alpha: alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = size
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..isAntiAlias = true;
      canvas.drawPath(fallback, strokePaint);
      return;
    }

    final path = Path()..moveTo(outline.first.dx, outline.first.dy);
    for (var i = 1; i < outline.length; i++) {
      path.lineTo(outline[i].dx, outline[i].dy);
    }
    path.close();

    if (postProcess == BrushPostProcess.watercolorBlur) {
      // 외곽선을 살짝 blur로 깔고, 그 위에 좀 더 진한 안쪽 패스를 한 번 더.
      final blurPaint = Paint()
        ..color = stroke.color.withValues(alpha: alpha)
        ..style = PaintingStyle.fill
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, size / 2)
        ..isAntiAlias = true;
      canvas.drawPath(path, blurPaint);
      final innerPaint = Paint()
        ..color = stroke.color.withValues(alpha: (alpha * 0.7).clamp(0.0, 1.0))
        ..style = PaintingStyle.fill
        ..isAntiAlias = true;
      canvas.drawPath(path, innerPaint);
    } else {
      canvas.drawPath(path, basePaint);
    }

    _applyPostProcess(canvas, stroke, basePaint, size, isDot: false);
  }

  void _applyPostProcess(
    ui.Canvas canvas,
    DrawingStroke stroke,
    Paint basePaint,
    double size, {
    required bool isDot,
  }) {
    if (postProcess != BrushPostProcess.crayonNoise) return;

    // crayon/pencil 결을 흉내내기 위한 작은 그레인 도트.
    // stroke.seed로 RNG를 고정해 리페인트 시 패턴이 흔들리지 않게 한다.
    final random = math.Random(stroke.seed ^ type.index);
    final dotPaint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final radius = size / 2;
    final grainAlpha = (alpha * 0.45).clamp(0.0, 1.0);
    const dotsPerPoint = 6;

    final minDist = math.max(radius * 0.5, 1.5);
    final minDistSq = minDist * minDist;
    Offset? prev;

    for (final point in stroke.points) {
      if (prev != null) {
        final dx = point.dx - prev.dx;
        final dy = point.dy - prev.dy;
        if (dx * dx + dy * dy < minDistSq) {
          for (var i = 0; i < dotsPerPoint; i++) {
            random.nextDouble();
            random.nextDouble();
            random.nextDouble();
          }
          continue;
        }
      }
      prev = point;

      for (var i = 0; i < dotsPerPoint; i++) {
        final angle = random.nextDouble() * 2 * math.pi;
        final dist = random.nextDouble() * radius;
        final dx = point.dx + dist * math.cos(angle);
        final dy = point.dy + dist * math.sin(angle);
        dotPaint.color = stroke.color.withValues(alpha: grainAlpha);
        canvas.drawCircle(
          Offset(dx, dy),
          0.6 + random.nextDouble() * 0.8,
          dotPaint,
        );
      }
    }
  }

  void _drawAirbrushSpray(ui.Canvas canvas, DrawingStroke stroke, double size) {
    // 기존 _drawAirbrush 알고리즘을 BrushPreset로 옮긴 것.
    final random = math.Random(stroke.seed);
    final dotPaint = Paint()
      ..style = PaintingStyle.fill
      ..blendMode = BlendMode.srcOver
      ..isAntiAlias = true;

    final radius = size / 2;
    const dotCount = 25;
    final minDist = radius * 0.3;
    final minDistSq = minDist * minDist;
    Offset? prev;

    for (final point in stroke.points) {
      if (prev != null) {
        final ddx = point.dx - prev.dx;
        final ddy = point.dy - prev.dy;
        if (ddx * ddx + ddy * ddy < minDistSq) {
          for (var i = 0; i < dotCount; i++) {
            random.nextDouble();
            random.nextDouble();
            random.nextDouble();
            random.nextDouble();
          }
          continue;
        }
      }
      prev = point;

      for (var i = 0; i < dotCount; i++) {
        final angle = random.nextDouble() * 2 * math.pi;
        final dist =
            random.nextDouble() * radius * (0.3 + random.nextDouble() * 0.7);
        final dx = point.dx + dist * math.cos(angle);
        final dy = point.dy + dist * math.sin(angle);
        final normalizedDist = dist / radius;
        final opacity = (1.0 - normalizedDist * 0.7) * 0.35;
        dotPaint.color = stroke.color.withValues(
          alpha: opacity.clamp(0.05, 0.4),
        );
        canvas.drawCircle(
          Offset(dx, dy),
          1.0 + random.nextDouble() * 1.2,
          dotPaint,
        );
      }
    }
  }
}

/// 후처리 종류.
enum BrushPostProcess {
  none,
  watercolorBlur,
  airbrushSpray,
  crayonNoise,
}

/// 잠금 자산 분류. Hive 키와 1:1 매핑된다.
///
/// - [none]: 모든 사용자 사용 가능
/// - [watercolor]: `watercolor_unlocked` 키
/// - [airbrush]: `airbrush_unlocked` 키
enum BrushLock { none, watercolor, airbrush }
