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
      final path = Path()
        ..moveTo(stroke.points.first.dx, stroke.points.first.dy);
      for (int i = 1; i < stroke.points.length; i++) {
        if (i < stroke.points.length - 1) {
          final mid = Offset(
            (stroke.points[i].dx + stroke.points[i + 1].dx) / 2,
            (stroke.points[i].dy + stroke.points[i + 1].dy) / 2,
          );
          path.quadraticBezierTo(
            stroke.points[i].dx,
            stroke.points[i].dy,
            mid.dx,
            mid.dy,
          );
        } else {
          path.lineTo(stroke.points[i].dx, stroke.points[i].dy);
        }
      }
      canvas.drawPath(path, paint);
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
      final path = Path()
        ..moveTo(stroke.points.first.dx, stroke.points.first.dy);
      for (int i = 1; i < stroke.points.length; i++) {
        if (i < stroke.points.length - 1) {
          final mid = Offset(
            (stroke.points[i].dx + stroke.points[i + 1].dx) / 2,
            (stroke.points[i].dy + stroke.points[i + 1].dy) / 2,
          );
          path.quadraticBezierTo(
            stroke.points[i].dx,
            stroke.points[i].dy,
            mid.dx,
            mid.dy,
          );
        } else {
          path.lineTo(stroke.points[i].dx, stroke.points[i].dy);
        }
      }
      canvas.drawPath(path, paint);
      canvas.drawPath(path, innerPaint);
    }
  }

  void _drawAirbrush(Canvas canvas, DrawingStroke stroke) {
    // Airbrush: scattered dots around each point simulate spray effect
    final random = math.Random(42);
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
  bool shouldRepaint(CanvasPainter oldDelegate) =>
      strokes.length != oldDelegate.strokes.length ||
      (strokes.isNotEmpty &&
          strokes.last.points.length !=
              (oldDelegate.strokes.isNotEmpty
                  ? oldDelegate.strokes.last.points.length
                  : 0));
}
