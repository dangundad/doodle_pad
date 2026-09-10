import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';

import 'package:doodle_pad/app/controllers/doodle_controller.dart';
import 'package:doodle_pad/app/data/models/drawing.dart';
import 'package:doodle_pad/app/pages/draw/widgets/canvas_painter.dart';
import 'package:doodle_pad/app/services/artwork_repository.dart';

/// 스토어 스크린샷 촬영용 더미 작품 시더.
///
/// `--dart-define=DOODLE_PAD_QA_SEED_ARTWORKS=true` 로 빌드했을 때만 동작하며
/// 일반 빌드에서는 상수 폴딩으로 완전히 제거된다. 앱 시작 시 보관함을 비우고
/// 프로그램으로 생성한 작품 8점을 실제 저장 경로(`ArtworkRepository`)로 넣는다.
/// 썸네일은 앱과 동일한 [CanvasPainter] 로 렌더한다.
abstract final class StoreScreenshotSeed {
  static const bool enabled = bool.fromEnvironment(
    'DOODLE_PAD_QA_SEED_ARTWORKS',
  );

  static const String _settingsBoxName = 'settings';
  static const String _drawingsBoxName = 'drawings';

  /// 기준 캔버스 크기(dp). DrawPage 캔버스는 전체 화면이라 360×800 폰 기준.
  static const Size canvasSize = Size(360, 800);
  static const double _thumbScale = 3;

  static Future<void> runIfEnabled() async {
    if (!enabled) return;
    try {
      await _run();
    } catch (e, st) {
      debugPrint('[StoreScreenshotSeed] failed: $e\n$st');
    }
  }

  static Future<void> _run() async {
    final repo = ArtworkRepository.instance;
    for (final d in repo.listAll()) {
      await repo.delete(d.id);
    }

    final artworks = _SeedArtworks.all();
    final now = DateTime.now();
    final box = Hive.box<Drawing>(_drawingsBoxName);
    for (var i = 0; i < artworks.length; i++) {
      final art = artworks[i];
      final id = 'seed_${i.toString().padLeft(2, '0')}';
      final bytes = await _renderThumbnail(art);
      await repo.save(
        id: id,
        canvasColor: art.canvasColor,
        canvasLogicalSize: canvasSize,
        referenceImagePath: null,
        strokes: art.strokes.map(_serialize).toList(),
        thumbnailPngBytes: bytes,
        name: art.name,
      );
      // 목록/히어로 순서와 보관함 날짜가 자연스럽도록 생성일을 뒤로 분산한다.
      final saved = box.get(id)!;
      final daysAgo = artworks.length - 1 - i;
      final ts = now
          .subtract(Duration(days: daysAgo, hours: daysAgo * 3))
          .millisecondsSinceEpoch;
      await box.put(
        id,
        Drawing(
          id: saved.id,
          createdAt: ts,
          updatedAt: ts,
          name: saved.name,
          canvasColor: saved.canvasColor,
          canvasLogicalWidth: saved.canvasLogicalWidth,
          canvasLogicalHeight: saved.canvasLogicalHeight,
          referenceImagePath: saved.referenceImagePath,
          strokes: saved.strokes,
          thumbnailPath: saved.thumbnailPath,
        ),
      );
    }

    // 툴바 퀵 행이 채워진 상태로 보이도록 최근 브러시/색상도 함께 심는다.
    final settings = Hive.box(_settingsBoxName);
    await settings.put(DoodleController.recentBrushesKey, <int>[
      BrushType.marker.stableId,
      BrushType.brush.stableId,
      BrushType.crayon.stableId,
      BrushType.pen.stableId,
    ]);
    await settings.put(DoodleController.recentColorsKey, <int>[
      _Ink.coral,
      _Ink.sky,
      _Ink.leaf,
      _Ink.sun,
      _Ink.ink,
    ]);
    await settings.put(
      DoodleController.lastBrushTypeKey,
      BrushType.marker.stableId,
    );
    debugPrint('[StoreScreenshotSeed] seeded ${artworks.length} artworks');
  }

  static Future<Uint8List> _renderThumbnail(_SeedArtwork art) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.scale(_thumbScale);
    CanvasPainter(
      strokes: art.strokes,
      bgColor: Color(art.canvasColor),
    ).paint(canvas, canvasSize);
    final image = await recorder.endRecording().toImage(
      (canvasSize.width * _thumbScale).round(),
      (canvasSize.height * _thumbScale).round(),
    );
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      return data!.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  }

  static SerializableStroke _serialize(DrawingStroke s) {
    final flat = <double>[];
    for (final p in s.points) {
      flat
        ..add(p.dx)
        ..add(p.dy);
    }
    return SerializableStroke(
      colorArgb: s.color.toARGB32(),
      width: s.width,
      isEraser: s.isEraser,
      brushTypeIndex: s.brushType.stableId,
      seed: s.seed,
      pointsXY: flat,
    );
  }
}

class _SeedArtwork {
  const _SeedArtwork({
    required this.name,
    required this.canvasColor,
    required this.strokes,
  });

  final String name;
  final int canvasColor;
  final List<DrawingStroke> strokes;
}

abstract final class _Ink {
  static const int ink = 0xFF1F2937;
  static const int coral = 0xFFEF6C57;
  static const int sun = 0xFFF7B32B;
  static const int sky = 0xFF3B82C4;
  static const int leaf = 0xFF3E9B5B;
  static const int rose = 0xFFE86FA0;
  static const int violet = 0xFF7C5CBF;
  static const int mint = 0xFF5CC8B8;
  static const int paper = 0xFFFFFFFF;
  static const int cream = 0xFFFFF6E5;
  static const int night = 0xFF1B2440;
}

/// 손그림 느낌을 위한 결정적 지터 + 도형 생성 헬퍼.
class _Pen {
  _Pen(int seed) : _rng = math.Random(seed);

  final math.Random _rng;
  final List<DrawingStroke> strokes = [];

  void add(
    List<Offset> pts,
    int color,
    double width,
    BrushType brush, {
    double jitter = 0.6,
  }) {
    // 도형은 y 130~620 기준으로 설계됐다. 상/하단 툴바(약 90dp / 580dp 이후)에
    // 가리지 않도록 중심(180, 380) 기준 0.88배 축소 후 위로 30dp 올린다.
    const fit = 0.88;
    const cx = 180.0, cy = 380.0, dy = -30.0;
    final jittered = [
      for (final p in pts)
        Offset(
          cx + (p.dx - cx) * fit + (_rng.nextDouble() - 0.5) * jitter,
          cy + (p.dy - cy) * fit + dy + (_rng.nextDouble() - 0.5) * jitter,
        ),
    ];
    strokes.add(
      DrawingStroke(
        points: jittered,
        color: Color(color),
        width: width * fit,
        brushType: brush,
        seed: _rng.nextInt(1 << 30),
      ),
    );
  }

  List<Offset> line(double x1, double y1, double x2, double y2, {int n = 14}) {
    return [
      for (var i = 0; i <= n; i++)
        Offset(x1 + (x2 - x1) * i / n, y1 + (y2 - y1) * i / n),
    ];
  }

  List<Offset> poly(List<Offset> corners, {int segs = 8}) {
    final out = <Offset>[];
    for (var i = 0; i < corners.length - 1; i++) {
      final a = corners[i];
      final b = corners[i + 1];
      for (var s = 0; s <= segs; s++) {
        if (s == 0 && i > 0) continue;
        out.add(Offset(
          a.dx + (b.dx - a.dx) * s / segs,
          a.dy + (b.dy - a.dy) * s / segs,
        ));
      }
    }
    return out;
  }

  List<Offset> arc(
    double cx,
    double cy,
    double r, {
    double start = 0,
    double sweep = math.pi * 2,
    int n = 40,
    double ry = -1,
  }) {
    final ryy = ry < 0 ? r : ry;
    return [
      for (var i = 0; i <= n; i++)
        Offset(
          cx + r * math.cos(start + sweep * i / n),
          cy + ryy * math.sin(start + sweep * i / n),
        ),
    ];
  }

  List<Offset> wave(
    double x1,
    double x2,
    double y, {
    double amp = 6,
    double periods = 3,
    int n = 40,
    double phase = 0,
  }) {
    return [
      for (var i = 0; i <= n; i++)
        Offset(
          x1 + (x2 - x1) * i / n,
          y + amp * math.sin(phase + periods * math.pi * 2 * i / n),
        ),
    ];
  }

  List<Offset> spiral(
    double cx,
    double cy,
    double rMax, {
    double turns = 3,
    int n = 90,
  }) {
    return [
      for (var i = 0; i <= n; i++)
        Offset(
          cx + rMax * i / n * math.cos(turns * math.pi * 2 * i / n),
          cy + rMax * i / n * math.sin(turns * math.pi * 2 * i / n),
        ),
    ];
  }

  List<Offset> heart(double cx, double cy, double s, {int n = 60}) {
    return [
      for (var i = 0; i <= n; i++)
        () {
          final t = math.pi * 2 * i / n;
          final x = 16 * math.pow(math.sin(t), 3);
          final y = 13 * math.cos(t) -
              5 * math.cos(2 * t) -
              2 * math.cos(3 * t) -
              math.cos(4 * t);
          return Offset(cx + x * s, cy - y * s);
        }(),
    ];
  }

  List<Offset> dot(double x, double y) => [Offset(x, y), Offset(x + 0.5, y)];
}

abstract final class _SeedArtworks {
  /// 저장 순서 = 오래된 것부터. 마지막 항목이 보관함 맨 앞/히어로 최상단.
  static List<_SeedArtwork> all() => [
        _kidDoodle(),
        _spirals(),
        _catSketch(),
        _balloons(),
        _nightCity(),
        _rainbow(),
        _flower(),
        _sunsetLake(),
      ];

  // 콘텐츠 영역: 툴바에 가려지지 않는 y 130~620 부근.
  static _SeedArtwork _sunsetLake() {
    final p = _Pen(1);
    // Sky bands (watercolor).
    final bands = [0xFFFFD27A, 0xFFFFA45C, 0xFFF2727E, 0xFFA66BB5];
    for (var i = 0; i < bands.length; i++) {
      final y = 200.0 + i * 34;
      p.add(p.wave(20, 340, y, amp: 4, periods: 1.5, n: 30),
          bands[i], 26, BrushType.watercolor);
      p.add(p.wave(24, 336, y + 14, amp: 4, periods: 1.5, n: 30, phase: 1),
          bands[i], 22, BrushType.watercolor);
    }
    // Sun.
    for (var r = 30.0; r > 4; r -= 7) {
      p.add(p.arc(236, 318, r, n: 36), 0xFFFF9B2F, 12, BrushType.marker);
    }
    // Mountains.
    p.add(
      p.poly([
        const Offset(0, 420),
        const Offset(70, 330),
        const Offset(130, 400),
        const Offset(190, 345),
        const Offset(260, 405),
        const Offset(320, 360),
        const Offset(360, 420),
      ], segs: 10),
      0xFF2E3A59,
      5,
      BrushType.fountainPen,
    );
    p.add(
      p.poly([
        const Offset(0, 430),
        const Offset(90, 385),
        const Offset(170, 425),
        const Offset(250, 390),
        const Offset(360, 440),
      ], segs: 10),
      0xFF3E4C73,
      4,
      BrushType.fountainPen,
    );
    // Lake.
    final lake = [0xFF4C8ED9, 0xFF3B7BC4, 0xFF2F6AAE];
    for (var i = 0; i < 7; i++) {
      p.add(
        p.wave(10, 350, 468.0 + i * 22, amp: 5, periods: 4, n: 48, phase: i * 0.9),
        lake[i % lake.length],
        10,
        BrushType.brush,
      );
    }
    // Reflections.
    for (var i = 0; i < 4; i++) {
      p.add(p.line(210 + i * 8, 470.0 + i * 24, 262 - i * 6, 470.0 + i * 24),
          0xFFFFE08A, 5, BrushType.highlighter);
    }
    // Birds.
    for (final b in [const Offset(90, 250), const Offset(120, 235), const Offset(150, 262)]) {
      p.add(
        p.poly([
          Offset(b.dx - 10, b.dy + 4),
          Offset(b.dx, b.dy - 3),
          Offset(b.dx + 10, b.dy + 4),
        ], segs: 5),
        _Ink.ink,
        2.5,
        BrushType.pen,
      );
    }
    return _SeedArtwork(
      name: 'Sunset Lake',
      canvasColor: _Ink.paper,
      strokes: p.strokes,
    );
  }

  static _SeedArtwork _flower() {
    final p = _Pen(2);
    const cx = 180.0, cy = 330.0;
    // Stem & leaves.
    p.add(p.wave(cy, 610, cx, amp: 6, periods: 1, n: 30).map((o) => Offset(o.dy, o.dx)).toList(),
        _Ink.leaf, 6, BrushType.brush);
    for (final (lc, lr) in [(const Offset(146, 500), 32.0), (const Offset(216, 545), 30.0)]) {
      for (var k = 1.0; k > 0.15; k -= 0.28) {
        p.add(p.arc(lc.dx, lc.dy, lr * k, ry: 14 * k, n: 30), _Ink.leaf, 8, BrushType.brush);
      }
    }
    // Petals.
    final petalColors = [0xFFF06292, 0xFFEC407A, 0xFFF48FB1];
    for (var k = 0; k < 8; k++) {
      final a = k * math.pi / 4;
      final pts = <Offset>[];
      for (var i = 0; i <= 40; i++) {
        final t = math.pi * 2 * i / 40;
        final rx = 62 * math.max(0.0, math.cos(t)) + 6;
        final r = rx;
        final px = r * math.cos(t) * 0.55 + 30;
        final py = r * math.sin(t) * 0.55;
        pts.add(Offset(
          cx + px * math.cos(a) - py * math.sin(a),
          cy + px * math.sin(a) + py * math.cos(a),
        ));
      }
      p.add(pts, petalColors[k % 3], 12, BrushType.marker);
      p.add(pts.map((o) => Offset(cx + (o.dx - cx) * 0.6, cy + (o.dy - cy) * 0.6)).toList(),
          petalColors[(k + 1) % 3], 14, BrushType.marker);
    }
    // Center.
    p.add(p.spiral(cx, cy, 26, turns: 3, n: 80), _Ink.sun, 9, BrushType.crayon);
    // Pollen dust.
    for (var i = 0; i < 10; i++) {
      final a = i * 0.63;
      p.add(p.dot(cx + 36 * math.cos(a), cy + 36 * math.sin(a)), 0xFFB8860B, 5, BrushType.pen);
    }
    // Small side flowers.
    for (final c in [const Offset(290, 470), const Offset(70, 420)]) {
      for (var k = 0; k < 6; k++) {
        final a = k * math.pi / 3;
        p.add(p.arc(c.dx + 16 * math.cos(a), c.dy + 16 * math.sin(a), 9, n: 20),
            _Ink.violet, 6, BrushType.brush);
      }
      p.add(p.arc(c.dx, c.dy, 6, n: 16), _Ink.sun, 6, BrushType.marker);
    }
    return _SeedArtwork(name: 'Spring Bloom', canvasColor: _Ink.paper, strokes: p.strokes);
  }

  static _SeedArtwork _rainbow() {
    final p = _Pen(3);
    final colors = [0xFFE53935, 0xFFFB8C00, 0xFFFDD835, 0xFF43A047, 0xFF1E88E5, 0xFF3949AB, 0xFF8E24AA];
    for (var i = 0; i < colors.length; i++) {
      p.add(p.arc(180, 470, 190.0 - i * 15, start: math.pi, sweep: math.pi, n: 60),
          colors[i], 8, BrushType.marker, jitter: 0.3);
    }
    // Clouds.
    for (final c in [const Offset(40, 470), const Offset(320, 470)]) {
      final blobs = [Offset(c.dx, c.dy), Offset(c.dx - 24, c.dy + 10), Offset(c.dx + 24, c.dy + 10), Offset(c.dx, c.dy + 18)];
      for (final b in blobs) {
        p.add(p.arc(b.dx, b.dy, 20, n: 30), 0xFFBFD9F5, 14, BrushType.brush);
        p.add(p.arc(b.dx, b.dy, 10, n: 20), 0xFFDDEBFA, 14, BrushType.brush);
      }
    }
    // Sun.
    p.add(p.spiral(300, 190, 28, turns: 4, n: 100), _Ink.sun, 8, BrushType.crayon);
    for (var i = 0; i < 12; i++) {
      final a = i * math.pi / 6;
      p.add(p.line(300 + 40 * math.cos(a), 190 + 40 * math.sin(a), 300 + 58 * math.cos(a), 190 + 58 * math.sin(a), n: 6),
          _Ink.sun, 5, BrushType.crayon);
    }
    // Grass.
    for (var x = 20.0; x < 350; x += 14) {
      p.add(p.line(x, 560, x + 5, 528 + (x % 3) * 6, n: 6), _Ink.leaf, 4, BrushType.pen);
    }
    p.add(p.wave(0, 360, 560, amp: 3, periods: 6, n: 60), _Ink.leaf, 6, BrushType.brush);
    return _SeedArtwork(name: 'After the Rain', canvasColor: _Ink.paper, strokes: p.strokes);
  }

  static _SeedArtwork _nightCity() {
    final p = _Pen(4);
    const outline = 0xFFE8ECF7;
    final buildings = [
      [20.0, 420.0, 70.0], [80.0, 340.0, 60.0], [150.0, 390.0, 50.0],
      [210.0, 300.0, 70.0], [290.0, 380.0, 60.0],
    ];
    for (final b in buildings) {
      final x = b[0], top = b[1], w = b[2];
      p.add(
        p.poly([Offset(x, 580), Offset(x, top), Offset(x + w, top), Offset(x + w, 580)], segs: 10),
        outline, 3, BrushType.pen,
      );
      for (var y = top + 18; y < 570; y += 26) {
        for (var wx = x + 12; wx < x + w - 8; wx += 20) {
          if ((wx + y) % 5 < 2) continue;
          p.add(p.line(wx, y, wx + 8, y, n: 3), 0xFFFFE066, 5, BrushType.highlighter);
        }
      }
    }
    p.add(p.line(0, 582, 360, 582, n: 20), outline, 3, BrushType.pen);
    // Moon.
    p.add(p.arc(300, 200, 34, start: -math.pi / 2, sweep: math.pi, n: 30), 0xFFFFE9A6, 10, BrushType.marker);
    p.add(p.arc(288, 200, 30, start: -math.pi / 2, sweep: math.pi, n: 30), 0xFFFFE9A6, 6, BrushType.marker);
    // Stars.
    final rng = math.Random(9);
    for (var i = 0; i < 26; i++) {
      final x = 20 + rng.nextDouble() * 320;
      final y = 150 + rng.nextDouble() * 170;
      if ((x - 300).abs() < 45 && (y - 200).abs() < 45) continue;
      p.add(p.dot(x, y), 0xFFFFFFFF, 2 + rng.nextDouble() * 2, BrushType.pen);
    }
    // Airbrush glow near the skyline.
    p.add(p.wave(0, 360, 300, amp: 6, periods: 2, n: 40), 0xFF5B6FB8, 26, BrushType.airbrush);
    return _SeedArtwork(name: 'City Lights', canvasColor: _Ink.night, strokes: p.strokes);
  }

  static _SeedArtwork _balloons() {
    final p = _Pen(5);
    final hearts = [
      (const Offset(120, 300), 5.0, 0xFFE53935),
      (const Offset(230, 260), 4.2, 0xFFEC407A),
      (const Offset(260, 400), 3.6, 0xFF8E24AA),
    ];
    for (final (c, s, color) in hearts) {
      for (var k = s; k > 0.6; k -= 0.7) {
        p.add(p.heart(c.dx, c.dy, k), color, 14, BrushType.watercolor, jitter: 1.2);
      }
      p.add(p.heart(c.dx, c.dy, s), color, 4, BrushType.pen);
      // String.
      p.add(
        p.wave(c.dy + 16 * s, 640, c.dx, amp: 8, periods: 1.5, n: 30)
            .map((o) => Offset(o.dy, o.dx))
            .toList(),
        _Ink.ink, 2.5, BrushType.pen,
      );
    }
    // Hand holding strings.
    p.add(p.arc(200, 660, 22, ry: 14, n: 30), 0xFFF3C5A5, 10, BrushType.marker);
    return _SeedArtwork(name: 'Balloons', canvasColor: _Ink.paper, strokes: p.strokes);
  }

  static _SeedArtwork _catSketch() {
    final p = _Pen(6);
    const g = 0xFF3C3C3C;
    p.add(p.arc(180, 300, 70, ry: 64, n: 60), g, 5, BrushType.pencil);
    // Ears.
    p.add(p.poly([const Offset(122, 262), const Offset(118, 190), const Offset(170, 240)]), g, 5, BrushType.pencil);
    p.add(p.poly([const Offset(238, 262), const Offset(242, 190), const Offset(190, 240)]), g, 5, BrushType.pencil);
    p.add(p.poly([const Offset(132, 250), const Offset(128, 210), const Offset(160, 240)]), 0xFFF2A7B8, 6, BrushType.crayon);
    p.add(p.poly([const Offset(228, 250), const Offset(232, 210), const Offset(200, 240)]), 0xFFF2A7B8, 6, BrushType.crayon);
    // Eyes.
    p.add(p.arc(152, 296, 10, ry: 13, n: 30), g, 4, BrushType.pencil);
    p.add(p.arc(208, 296, 10, ry: 13, n: 30), g, 4, BrushType.pencil);
    p.add(p.line(152, 288, 152, 304, n: 6), g, 6, BrushType.pen);
    p.add(p.line(208, 288, 208, 304, n: 6), g, 6, BrushType.pen);
    // Nose & mouth.
    p.add(p.poly([const Offset(172, 322), const Offset(188, 322), const Offset(180, 332), const Offset(172, 322)]), 0xFFE58A9E, 5, BrushType.crayon);
    p.add(p.arc(170, 334, 10, start: 0, sweep: math.pi, n: 20), g, 3, BrushType.pencil);
    p.add(p.arc(190, 334, 10, start: 0, sweep: math.pi, n: 20), g, 3, BrushType.pencil);
    // Whiskers.
    for (final dy in [-6.0, 4.0, 14.0]) {
      p.add(p.line(150, 326 + dy, 90, 320 + dy * 2), g, 2.5, BrushType.pencil);
      p.add(p.line(210, 326 + dy, 270, 320 + dy * 2), g, 2.5, BrushType.pencil);
    }
    // Cheeks.
    p.add(p.arc(135, 330, 12, n: 24), 0xFFF9C5D1, 8, BrushType.crayon);
    p.add(p.arc(225, 330, 12, n: 24), 0xFFF9C5D1, 8, BrushType.crayon);
    // Body.
    p.add(p.arc(180, 470, 92, ry: 110, start: math.pi * 1.15, sweep: math.pi * 1.7, n: 70), g, 5, BrushType.pencil);
    p.add(p.line(180, 470, 180, 570, n: 12), g, 3, BrushType.pencil);
    // Paws.
    p.add(p.arc(140, 575, 22, ry: 12, n: 30), g, 4, BrushType.pencil);
    p.add(p.arc(220, 575, 22, ry: 12, n: 30), g, 4, BrushType.pencil);
    // Tail.
    p.add(p.arc(300, 520, 45, ry: 70, start: math.pi * 0.9, sweep: -math.pi * 1.1, n: 40), g, 5, BrushType.pencil);
    // Stripes.
    for (var i = 0; i < 3; i++) {
      p.add(p.arc(180, 410 + i * 34, 60 - i * 8, ry: 10, start: math.pi, sweep: math.pi, n: 20), 0xFFD58A3A, 6, BrushType.crayon);
    }
    return _SeedArtwork(name: 'Mochi the Cat', canvasColor: _Ink.paper, strokes: p.strokes);
  }

  static _SeedArtwork _spirals() {
    final p = _Pen(7);
    final items = [
      (const Offset(110, 260), 70.0, _Ink.coral),
      (const Offset(250, 330), 90.0, _Ink.sky),
      (const Offset(120, 470), 80.0, _Ink.mint),
      (const Offset(260, 540), 60.0, _Ink.violet),
      (const Offset(200, 190), 40.0, _Ink.sun),
    ];
    for (final (c, r, color) in items) {
      p.add(p.spiral(c.dx, c.dy, r, turns: 3.5, n: 120), color, 9, BrushType.brush, jitter: 1.0);
    }
    for (final (c, r, color) in items) {
      p.add(p.arc(c.dx, c.dy, r + 12, n: 50), color, 18, BrushType.airbrush);
    }
    return _SeedArtwork(name: 'Swirl Study', canvasColor: _Ink.cream, strokes: p.strokes);
  }

  static _SeedArtwork _kidDoodle() {
    final p = _Pen(8);
    // Sun.
    p.add(p.arc(70, 190, 30, n: 40), _Ink.sun, 9, BrushType.crayon);
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4;
      p.add(p.line(70 + 40 * math.cos(a), 190 + 40 * math.sin(a), 70 + 56 * math.cos(a), 190 + 56 * math.sin(a), n: 5), _Ink.sun, 6, BrushType.crayon);
    }
    // House.
    p.add(p.poly([const Offset(110, 470), const Offset(110, 360), const Offset(250, 360), const Offset(250, 470), const Offset(110, 470)]), _Ink.coral, 7, BrushType.crayon);
    p.add(p.poly([const Offset(100, 362), const Offset(180, 290), const Offset(260, 362)]), 0xFFB5651D, 7, BrushType.crayon);
    p.add(p.poly([const Offset(165, 470), const Offset(165, 420), const Offset(195, 420), const Offset(195, 470)]), 0xFF8D6E63, 6, BrushType.crayon);
    p.add(p.poly([const Offset(125, 380), const Offset(125, 405), const Offset(150, 405), const Offset(150, 380), const Offset(125, 380)]), _Ink.sky, 5, BrushType.crayon);
    p.add(p.poly([const Offset(210, 380), const Offset(210, 405), const Offset(235, 405), const Offset(235, 380), const Offset(210, 380)]), _Ink.sky, 5, BrushType.crayon);
    // Tree.
    p.add(p.line(300, 470, 300, 410, n: 10), 0xFF8D6E63, 9, BrushType.crayon);
    p.add(p.arc(300, 385, 34, n: 40), _Ink.leaf, 12, BrushType.crayon);
    p.add(p.arc(300, 385, 16, n: 24), _Ink.leaf, 12, BrushType.crayon);
    // Ground & flowers.
    p.add(p.wave(0, 360, 480, amp: 4, periods: 5, n: 50), _Ink.leaf, 8, BrushType.crayon);
    for (var x = 40.0; x < 340; x += 60) {
      p.add(p.line(x, 480, x, 520, n: 6), _Ink.leaf, 3, BrushType.pen);
      p.add(p.arc(x, 522, 7, n: 16), _Ink.rose, 6, BrushType.marker);
    }
    // Smiley.
    p.add(p.arc(180, 590, 32, n: 40), _Ink.ink, 4, BrushType.pen);
    p.add(p.dot(168, 582), _Ink.ink, 6, BrushType.pen);
    p.add(p.dot(192, 582), _Ink.ink, 6, BrushType.pen);
    p.add(p.arc(180, 592, 16, start: 0.3, sweep: math.pi - 0.6, n: 20), _Ink.ink, 4, BrushType.pen);
    return _SeedArtwork(name: 'My Home', canvasColor: _Ink.paper, strokes: p.strokes);
  }
}
