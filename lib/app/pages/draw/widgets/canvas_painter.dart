import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:doodle_pad/app/controllers/doodle_controller.dart';

class CanvasPainter extends CustomPainter {
  final List<DrawingStroke> strokes;
  final Color bgColor;

  CanvasPainter({required this.strokes, required this.bgColor});

  @override
  void paint(Canvas canvas, Size size) {
    // Fill background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = bgColor,
    );

    // saveLayer required for BlendMode.clear (eraser) to work correctly
    canvas.saveLayer(
        Rect.fromLTWH(0, 0, size.width, size.height), Paint());

    for (final stroke in strokes) {
      if (stroke.points.isEmpty) continue;

      switch (stroke.brushType) {
        case BrushType.watercolor:
          _drawWatercolor(canvas, stroke);
          break;
        case BrushType.airbrush:
          _drawAirbrush(canvas, stroke);
          break;
        case BrushType.eraser:
          _drawEraser(canvas, stroke);
          break;
        default:
          _drawNormal(canvas, stroke);
          break;
      }
    }

    canvas.restore();
  }

  /// Build a smooth Bezier path through [points].
  ///
  /// Uses midpoint-chaining quadratic Bezier curves so every segment is
  /// C1-continuous (tangent-matched at joins).  The final segment goes
  /// directly to the last point via a quadratic curve (control point =
  /// the second-to-last raw point), removing the straight-line kink that
  /// `lineTo` produces when the finger is lifted mid-curve.
  Path _buildSmoothPath(List<Offset> points) {
    final path = Path()
      ..moveTo(points.first.dx, points.first.dy);

    if (points.length == 2) {
      // Only two points: straight line is the best we can do.
      path.lineTo(points[1].dx, points[1].dy);
      return path;
    }

    // For every interior point, curve from the previous midpoint to the
    // next midpoint with the interior point as the Bezier control.
    for (int i = 1; i < points.length - 1; i++) {
      final mid = Offset(
        (points[i].dx + points[i + 1].dx) / 2,
        (points[i].dy + points[i + 1].dy) / 2,
      );
      path.quadraticBezierTo(
        points[i].dx,
        points[i].dy,
        mid.dx,
        mid.dy,
      );
    }

    // Fix: finish the path with a curve to the true last point instead of
    // a straight lineTo, so the stroke tip is smooth.
    final n = points.length;
    path.quadraticBezierTo(
      points[n - 2].dx,
      points[n - 2].dy,
      points[n - 1].dx,
      points[n - 1].dy,
    );

    return path;
  }

  void _drawNormal(Canvas canvas, DrawingStroke stroke) {
    final paint = Paint()
      ..color = stroke.isEraser ? Colors.transparent : stroke.color
      ..strokeWidth = stroke.width
      ..strokeCap = stroke.cap
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..blendMode =
          stroke.isEraser ? BlendMode.clear : BlendMode.srcOver;

    if (stroke.points.length == 1) {
      canvas.drawCircle(
        stroke.points.first,
        stroke.width / 2,
        Paint()
          ..color = stroke.isEraser ? Colors.transparent : stroke.color
          ..style = PaintingStyle.fill
          ..blendMode =
              stroke.isEraser ? BlendMode.clear : BlendMode.srcOver,
      );
    } else {
      canvas.drawPath(_buildSmoothPath(stroke.points), paint);
    }
  }

  void _drawEraser(Canvas canvas, DrawingStroke stroke) {
    _drawNormal(canvas, stroke);
  }

  void _drawWatercolor(Canvas canvas, DrawingStroke stroke) {
    // Watercolor: low opacity + blur gives soft, layered look
    final blurRadius = stroke.width / 2;
    final paint = Paint()
      ..color = stroke.color.withValues(alpha: 0.28)
      ..strokeWidth = stroke.width * 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, blurRadius)
      ..blendMode = BlendMode.srcOver;

    // Inner layer: slightly more opaque for center definition
    final innerPaint = Paint()
      ..color = stroke.color.withValues(alpha: 0.15)
      ..strokeWidth = stroke.width * 1.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..blendMode = BlendMode.srcOver;

    if (stroke.points.length == 1) {
      canvas.drawCircle(stroke.points.first, stroke.width, paint);
      canvas.drawCircle(stroke.points.first, stroke.width * 0.6, innerPaint);
    } else {
      final path = _buildSmoothPath(stroke.points);
      canvas.drawPath(path, paint);
      canvas.drawPath(path, innerPaint);
    }
  }

  void _drawAirbrush(Canvas canvas, DrawingStroke stroke) {
    // Airbrush: scattered dots around each point simulate spray effect.
    // Use the stroke's fixed seed so the spray pattern is identical on every
    // repaint, preventing the "flickering dots" artifact that occurs when other
    // strokes are added/removed and this stroke is re-drawn with a new Random.
    final random = math.Random(stroke.seed);
    final dotPaint = Paint()
      ..style = PaintingStyle.fill
      ..blendMode = BlendMode.srcOver;

    final radius = stroke.width / 2;
    const dotCount = 25;

    for (final point in stroke.points) {
      for (int i = 0; i < dotCount; i++) {
        // Random angle and distance within the spray radius
        final angle = random.nextDouble() * 2 * math.pi;
        // Gaussian-like distribution: more dots near center
        final dist = random.nextDouble() * radius * (0.3 + random.nextDouble() * 0.7);
        final dx = point.dx + dist * math.cos(angle);
        final dy = point.dy + dist * math.sin(angle);

        // Dots closer to center are more opaque
        final normalizedDist = dist / radius;
        final opacity = (1.0 - normalizedDist * 0.7) * 0.35;

        dotPaint.color = stroke.color.withValues(alpha: opacity.clamp(0.05, 0.4));
        canvas.drawCircle(Offset(dx, dy), 1.0 + random.nextDouble() * 1.2, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(CanvasPainter oldDelegate) {
    // The controller passes the same RxList reference on every rebuild, so
    // comparing strokes.length or strokes.last.points.length between old and
    // new delegates always yields identical values (same object).  Returning
    // `true` unconditionally ensures the canvas is repainted whenever Obx
    // triggers a rebuild — which is the correct, desired behaviour here.
    // Performance is acceptable because Obx only rebuilds when an observable
    // actually changes (strokes.refresh() / strokes.add() / strokes.remove()).
    if (bgColor != oldDelegate.bgColor) return true;
    // Always repaint: delegate instances are different only when Obx fires.
    return true;
  }
}
