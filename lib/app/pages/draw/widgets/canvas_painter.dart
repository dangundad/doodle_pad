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
          // Smooth curves with quadratic bezier
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

    canvas.restore();
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
