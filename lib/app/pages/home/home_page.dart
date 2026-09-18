import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:doodle_pad/app/admob/ads_banner.dart';
import 'package:doodle_pad/app/bindings/app_binding.dart';
import 'package:doodle_pad/app/controllers/doodle_controller.dart';
import 'package:doodle_pad/app/controllers/setting_controller.dart';
import 'package:doodle_pad/app/data/brushes/brush_presets.dart';
import 'package:doodle_pad/app/data/models/drawing.dart';
import 'package:doodle_pad/app/routes/app_pages.dart';
import 'package:doodle_pad/app/services/hive_service.dart';
import 'package:doodle_pad/app/theme/app_theme.dart';
import 'package:doodle_pad/app/widgets/app_ui.dart';
import 'package:doodle_pad/app/widgets/exit_bottom_sheet.dart';

/// 홈에서 그리기 화면으로 진입할 때 호출.
/// 작업 중인 그림이 남아 있으면 "이어 그리기 / 새로 시작" 다이얼로그를 띄우고,
/// 사용자가 새로 시작을 고르거나 캔버스가 비어있으면 자동으로 clearCanvas() 한다.
Future<void> _enterDrawing(SettingController settingCtrl) async {
  final ctrl = DoodleController.to;
  if (settingCtrl.hapticEnabled.value) {
    ctrl.hapticSelection();
  }

  if (!ctrl.hasDrawableContent) {
    ctrl.clearCanvas();
    await AppBinding.markOnboardingSeen();
    await Get.offAllNamed(Routes.DRAW);
    return;
  }

  final continueExisting = await AppConfirmDialog.show(
    icon: LucideIcons.brush,
    title: 'continue_or_new_title'.tr,
    message: 'continue_or_new_desc'.tr,
    confirmLabel: 'continue_drawing'.tr,
    cancelLabel: 'start_new'.tr,
    barrierDismissible: true,
  );

  if (continueExisting == null) {
    // 사용자가 다이얼로그를 닫음 — 현재 작품과 화면 상태를 유지하고 진입 취소.
    return;
  }
  if (!continueExisting) {
    ctrl.clearCanvas();
  }
  await AppBinding.markOnboardingSeen();
  await Get.offAllNamed(Routes.DRAW);
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          ExitBottomSheet.show();
        }
      },
      child: Scaffold(
        backgroundColor: cs.surface,
        appBar: AppBar(
          title: Text(
            'app_name'.tr,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            IconButton(
              icon: Icon(LucideIcons.crown, size: 20.r),
              tooltip: 'premium_title'.tr,
              onPressed: () => Get.toNamed(Routes.PREMIUM),
            ),
            IconButton(
              icon: Icon(LucideIcons.settings, size: 20.r),
              tooltip: 'settings'.tr,
              onPressed: () => Get.toNamed(Routes.SETTINGS),
            ),
            SizedBox(width: 4.w),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 20.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _SketchHero(reduceMotion: reduceMotion),
                      SizedBox(height: 32.h),
                      const _TitleBlock(),
                      SizedBox(height: 24.h),
                      const _StartDrawingCta(),
                      SizedBox(height: 12.h),
                      const _MyArtworksCard(),
                    ],
                  ),
                ),
              ),
              const AdBannerBar(),
            ],
          ),
        ),
      ),
    );
  }
}

/// 홈 히어로 — 스프링 노트 한 장.
///
/// 작품이 있으면 최신 작품을, 없으면 앱의 브러시 엔진이 그린 낙서 샘플을
/// 종이 위에 올린다. 이전에는 작품이 없을 때 빈 종이 세 장만 겹쳐 있어서
/// 다크 테마에서는 배경과 같은 검정이라 사실상 아무것도 보이지 않았다.
class _SketchHero extends StatelessWidget {
  const _SketchHero({required this.reduceMotion});

  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, 12 * (1 - value)),
          child: child,
        ),
      ),
      child: ValueListenableBuilder(
        key: const ValueKey('home-hero-artwork'),
        valueListenable: HiveService.to.drawingsBox.listenable(),
        builder: (context, Box<Drawing> box, _) {
          final recent = box.values.toList()
            ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
          final latest = recent
              .map((d) => d.thumbnailPath)
              .firstWhere((path) => path != null, orElse: () => null);
          return _NotePad(thumbnailPath: latest);
        },
      ),
    );
  }
}

/// 스프링 노트 한 장 + 뒤에 살짝 비치는 두 번째 장.
class _NotePad extends StatelessWidget {
  const _NotePad({this.thumbnailPath});

  final String? thumbnailPath;

  /// 종이는 라이트/다크 어디서나 종이색이다. 다크에서 표면색을 쓰면 배경과
  /// 같은 검정이 되어 히어로가 사라진다.
  static const Color paper = Color(0xFFFDFBF5);
  static const Color binding = Color(0xFF2F4FBF);
  static const Color _edge = Color(0x22000000);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final height = 212.h.clamp(178.0, 236.0);
    final width = (height * 1.32).clamp(0.0, 320.w);
    final radius = BorderRadius.circular(AppTheme.radiusSm.r);

    Widget sheet({required Widget child, bool muted = false}) => Container(
      width: width,
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: muted ? const Color(0xFFEFEBE0) : paper,
        borderRadius: radius,
        border: Border.all(color: _edge),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: muted ? 0.06 : 0.12),
            blurRadius: muted ? 6 : 14,
            offset: Offset(0, muted ? 2 : 6),
          ),
        ],
      ),
      child: child,
    );

    return SizedBox(
      height: height + 10.h,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 뒤에 한 장만 비스듬히 남긴다. 세 장을 겹치면 "묶음"이 아니라
          // 무엇을 봐야 할지 모르는 더미가 된다.
          Transform.translate(
            offset: Offset(14.w, 8.h),
            child: Transform.rotate(
              angle: 0.035,
              child: sheet(child: const SizedBox.shrink(), muted: true),
            ),
          ),
          sheet(
            child: Column(
              children: [
                SizedBox(
                  height: 22.h,
                  width: double.infinity,
                  child: CustomPaint(painter: const _BindingPainter()),
                ),
                Expanded(
                  // SizedBox.expand 가 없으면 Image 는 가로 제약이 loose 라
                  // 제 비율대로만 자리를 잡는다. 세로로 긴 작품 썸네일이
                  // 종이 한가운데 좁은 띠로 찍히던 이유다.
                  child: SizedBox.expand(
                    child: thumbnailPath == null
                        ? CustomPaint(
                            painter: const _SampleDoodlePainter(),
                            size: Size.infinite,
                          )
                        : Image.file(
                            File(thumbnailPath!),
                            fit: BoxFit.cover,
                            filterQuality: FilterQuality.medium,
                            errorBuilder: (_, _, _) => CustomPaint(
                              painter: const _SampleDoodlePainter(),
                              size: Size.infinite,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 노트 상단의 스프링 링 + 절취선. 런처 아이콘의 스프링 노트와 같은 어휘다.
class _BindingPainter extends CustomPainter {
  const _BindingPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const ringCount = 7;
    final ring = Paint()
      ..color = _NotePad.binding
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.height * 0.11
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < ringCount; i++) {
      final cx = size.width * (i + 0.5) / ringCount;
      final rect = Rect.fromCenter(
        center: Offset(cx, size.height * 0.42),
        width: size.height * 0.46,
        height: size.height * 0.78,
      );
      // 위가 열린 링 — 종이를 물고 있는 모양.
      canvas.drawArc(rect, -math.pi * 0.86, math.pi * 1.72, false, ring);
    }

    // 절취선 — 점선 한 줄로 종이를 뜯는 자리를 표시한다.
    final dash = Paint()
      ..color = const Color(0x1F1E1B16)
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;
    final y = size.height - 1;
    for (double x = 4; x < size.width - 4; x += 8) {
      canvas.drawLine(Offset(x, y), Offset(x + 4, y), dash);
    }
  }

  @override
  bool shouldRepaint(covariant _BindingPainter oldDelegate) => false;
}

/// 작품이 없을 때 종이를 채우는 샘플 낙서.
///
/// 장식 일러스트가 아니라 **앱이 실제로 쓰는 브러시 엔진**(`BrushPresets`)으로
/// 그린다. 크레파스 무지개 / 마커 물결 / 펜 별 — 사용자가 첫 획을 그었을 때
/// 나올 결과물과 같은 질감이다.
class _SampleDoodlePainter extends CustomPainter {
  const _SampleDoodlePainter();

  static const Color _red = Color(0xFFE53935);
  static const Color _yellow = Color(0xFFF2B01E);
  static const Color _green = Color(0xFF43A047);
  static const Color _blue = Color(0xFF2F4FBF);
  static const Color _ink = Color(0xFF1E1B16);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    // 종이 가장자리에 획이 닿으면 잘린 그림처럼 보인다. 여백을 두고 그린다.
    final inset = Rect.fromLTWH(
      size.width * 0.08,
      size.height * 0.10,
      size.width * 0.84,
      size.height * 0.80,
    );
    canvas.save();
    canvas.translate(inset.left, inset.top);
    for (final stroke in _strokes(inset.size)) {
      BrushPresets.of(stroke.brushType).render(canvas, stroke);
    }
    canvas.restore();
  }

  List<DrawingStroke> _strokes(Size size) {
    final w = size.width;
    final h = size.height;
    final rainbowCenter = Offset(w * 0.26, h * 0.94);

    return [
      for (final (i, color) in [_red, _yellow, _green].indexed)
        DrawingStroke(
          points: _arc(rainbowCenter, h * (0.46 - i * 0.11)),
          color: color,
          width: 5,
          brushType: BrushType.crayon,
          seed: 11 + i,
        ),
      DrawingStroke(
        points: _wave(Offset(w * 0.56, h * 0.74), w * 0.44, h * 0.08),
        color: _blue,
        width: 3.5,
        brushType: BrushType.marker,
        seed: 21,
      ),
      DrawingStroke(
        points: _star(Offset(w * 0.75, h * 0.28), h * 0.19),
        color: _ink,
        width: 3.2,
        brushType: BrushType.pen,
        seed: 31,
      ),
    ];
  }

  /// 위쪽 반원(무지개 한 줄).
  List<Offset> _arc(Offset center, double radius) => [
    for (var i = 0; i <= 28; i++)
      Offset(
        center.dx + radius * math.cos(math.pi + math.pi * i / 28),
        center.dy + radius * math.sin(math.pi + math.pi * i / 28),
      ),
  ];

  /// 물결 두 마루.
  List<Offset> _wave(Offset start, double length, double amplitude) => [
    for (var i = 0; i <= 24; i++)
      Offset(
        start.dx + length * i / 24,
        start.dy - amplitude * math.sin(math.pi * 2 * i / 24),
      ),
  ];

  /// 한 획으로 그리는 오각별.
  List<Offset> _star(Offset center, double radius) {
    final corners = [
      for (var i = 0; i < 6; i++)
        Offset(
          center.dx +
              radius * math.cos(-math.pi / 2 + (i * 4) * math.pi * 2 / 10),
          center.dy +
              radius * math.sin(-math.pi / 2 + (i * 4) * math.pi * 2 / 10),
        ),
    ];
    final points = <Offset>[];
    for (var i = 0; i < corners.length - 1; i++) {
      for (var t = 0; t <= 6; t++) {
        points.add(Offset.lerp(corners[i], corners[i + 1], t / 6)!);
      }
    }
    return points;
  }

  @override
  bool shouldRepaint(covariant _SampleDoodlePainter oldDelegate) => false;
}

/// 제목 블록 — 앱 이름은 AppBar 가 이미 달고 있으므로 반복하지 않는다.
/// 홈에서 필요한 말은 "무엇을 할 수 있는가" 하나다.
class _TitleBlock extends StatelessWidget {
  const _TitleBlock();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          key: const ValueKey('home-title'),
          'home_headline'.tr,
          style: TextStyle(
            fontSize: isRtl ? 24.sp : 27.sp,
            fontWeight: FontWeight.w800,
            letterSpacing: isRtl ? 0 : -0.7,
            height: 1.2,
            color: cs.onSurface,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: 8.h),
        Text(
          key: const ValueKey('home-subtitle'),
          'app_subtitle'.tr,
          style: TextStyle(
            fontSize: 15.sp,
            height: 1.4,
            color: cs.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}


class _StartDrawingCta extends StatelessWidget {
  const _StartDrawingCta();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final settingCtrl = SettingController.to;

    return Tooltip(
      key: const ValueKey('home-start-cta'),
      message: 'start_drawing'.tr,
      child: Material(
        color: cs.primary,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd.r),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd.r),
          onTap: () => _enterDrawing(settingCtrl),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 16.h),
            child: Row(
              children: [
                Icon(LucideIcons.brush, size: 22.r, color: cs.onPrimary),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    'start_drawing'.tr,
                    style: TextStyle(
                      fontSize: 17.sp,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                      color: cs.onPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Directionality.of(context) == TextDirection.rtl
                      ? LucideIcons.arrowLeft
                      : LucideIcons.arrowRight,
                  size: 20.r,
                  color: cs.onPrimary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 작품 보관함 진입 — drawings box를 관찰해 작품 수를 실시간 반영.
class _MyArtworksCard extends StatelessWidget {
  const _MyArtworksCard();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ValueListenableBuilder(
      valueListenable: HiveService.to.drawingsBox.listenable(),
      builder: (context, Box<Drawing> box, _) {
        final count = box.length;
        return AppPanel(
          onTap: () => Get.toNamed(Routes.GALLERY),
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          child: Row(
            children: [
              const IconBadge(LucideIcons.images, tone: IconBadgeTone.accent),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'gallery_title'.tr,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      '${'gallery_saved_count'.tr} $count',
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: cs.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const DirectionalChevron(),
            ],
          ),
        );
      },
    );
  }
}
