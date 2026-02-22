import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

enum BrushType { pen, marker, eraser }

class DrawingStroke {
  final List<Offset> points;
  final Color color;
  final double width;
  final bool isEraser;
  final StrokeCap cap;

  DrawingStroke({
    required this.points,
    required this.color,
    required this.width,
    this.isEraser = false,
    this.cap = StrokeCap.round,
  });
}

class DoodleController extends GetxController {
  static DoodleController get to => Get.find();

  static const _maxUndo = 20;

  // Drawing state
  final strokes = <DrawingStroke>[].obs;
  DrawingStroke? _currentStroke;
  final _undoStack = <DrawingStroke>[];

  // Brush settings
  final brushType = BrushType.pen.obs;
  final brushColor = 0xFF000000.obs;
  final brushSize = 6.0.obs;

  // Color palette (16 colors)
  static const colorPalette = [
    0xFF000000, // black
    0xFF424242, // dark grey
    0xFF9E9E9E, // grey
    0xFFFFFFFF, // white
    0xFFF44336, // red
    0xFFFF5722, // deep orange
    0xFFFF9800, // orange
    0xFFFFEB3B, // yellow
    0xFF4CAF50, // green
    0xFF009688, // teal
    0xFF2196F3, // blue
    0xFF9C27B0, // purple
    0xFFE91E63, // pink
    0xFF795548, // brown
    0xFF00BCD4, // cyan
    0xFF8BC34A, // light green
  ];

  // Canvas RepaintBoundary key
  final canvasKey = GlobalKey();

  bool get canUndo => strokes.isNotEmpty;
  bool get canRedo => _undoStack.isNotEmpty;

  void startStroke(Offset point) {
    final isEraser = brushType.value == BrushType.eraser;
    final isMarker = brushType.value == BrushType.marker;
    _currentStroke = DrawingStroke(
      points: [point],
      color: isEraser
          ? Colors.transparent
          : Color(brushColor.value),
      width: brushSize.value *
          (isEraser
              ? 4.0
              : isMarker
                  ? 2.5
                  : 1.0),
      isEraser: isEraser,
      cap: isMarker ? StrokeCap.square : StrokeCap.round,
    );
    _undoStack.clear();
    strokes.add(_currentStroke!);
  }

  void continueStroke(Offset point) {
    if (_currentStroke == null) return;
    _currentStroke!.points.add(point);
    strokes.refresh();
  }

  void endStroke() {
    _currentStroke = null;
  }

  void undo() {
    if (strokes.isEmpty) return;
    final stroke = strokes.removeLast();
    if (_undoStack.length >= _maxUndo) _undoStack.removeAt(0);
    _undoStack.add(stroke);
  }

  void redo() {
    if (_undoStack.isEmpty) return;
    strokes.add(_undoStack.removeLast());
  }

  void clearCanvas() {
    strokes.clear();
    _undoStack.clear();
  }

  Future<void> shareCanvas() async {
    final boundary =
        canvasKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;
    try {
      final image = await boundary.toImage(pixelRatio: 3);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final bytes = byteData.buffer.asUint8List();
      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/doodle_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(bytes);
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path, mimeType: 'image/png')]),
      );
    } catch (e) {
      Get.snackbar('error'.tr, '$e', snackPosition: SnackPosition.BOTTOM);
    }
  }
}
