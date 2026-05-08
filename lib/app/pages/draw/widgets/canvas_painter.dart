import 'package:flutter/material.dart';

import 'package:doodle_pad/app/controllers/doodle_controller.dart';
import 'package:doodle_pad/app/data/brushes/brush_presets.dart';

class CanvasPainter extends CustomPainter {
  final List<DrawingStroke> strokes;
  final Color bgColor;

  CanvasPainter({required this.strokes, required this.bgColor});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    // Fill background
    canvas.drawRect(rect, Paint()..color = bgColor);

    // saveLayer is required for BlendMode.clear (eraser) to work correctly.
    // Only allocate the layer when at least one eraser stroke exists.
    final hasEraser = strokes.any((s) => s.brushType == BrushType.eraser);
    if (hasEraser) {
      canvas.saveLayer(rect, Paint());
    }

    for (final stroke in strokes) {
      if (stroke.points.isEmpty) continue;

      if (stroke.brushType == BrushType.eraser) {
        _drawEraser(canvas, stroke);
      } else {
        BrushPresets.of(stroke.brushType).render(canvas, stroke);
      }
    }

    if (hasEraser) {
      canvas.restore();
    }
  }

  /// 부드러운 quadratic bezier path. eraser와 outline-empty fallback에서만 사용한다.
  Path _buildSmoothPath(List<Offset> points) {
    final path = Path()..moveTo(points.first.dx, points.first.dy);

    if (points.length == 1) {
      return path;
    }

    if (points.length == 2) {
      path.lineTo(points[1].dx, points[1].dy);
      return path;
    }

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

    final n = points.length;
    path.quadraticBezierTo(
      points[n - 2].dx,
      points[n - 2].dy,
      points[n - 1].dx,
      points[n - 1].dy,
    );

    return path;
  }

  void _drawEraser(Canvas canvas, DrawingStroke stroke) {
    final paint = Paint()
      ..color = Colors.transparent
      ..strokeWidth = stroke.width
      ..strokeCap = stroke.cap
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..blendMode = BlendMode.clear;

    if (stroke.points.length == 1) {
      final dotPaint = Paint()
        ..color = Colors.transparent
        ..style = PaintingStyle.fill
        ..blendMode = BlendMode.clear;
      canvas.drawCircle(stroke.points.first, stroke.width / 2, dotPaint);
    } else {
      canvas.drawPath(_buildSmoothPath(stroke.points), paint);
    }
  }

  @override
  bool shouldRepaint(CanvasPainter oldDelegate) {
    // Obx rebuilds this widget only when an observable actually changes
    // (strokes.refresh() / strokes.add() / strokes.remove()), so returning
    // true is safe and correct — new delegate instances only appear on
    // real data changes.
    return true;
  }
}
