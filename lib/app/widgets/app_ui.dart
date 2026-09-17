import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:doodle_pad/app/theme/app_theme.dart';

/// 앱 공통 UI 프리미티브.
///
/// 모든 화면이 같은 표면·헤어라인·반경 규칙을 쓰도록 여기서만 정의한다.
/// 페이지 파일에서는 색상을 직접 만들지 말고 이 위젯들을 조합한다.

/// 헤어라인 테두리를 두른 표면 패널. 그림자 대신 1px 외곽선으로 구분한다.
class AppPanel extends StatelessWidget {
  const AppPanel({
    super.key,
    required this.child,
    this.padding,
    this.color,
    this.radius = AppTheme.radiusMd,
    this.outlined = true,
    this.onTap,
    this.onLongPress,
    this.clip = Clip.antiAlias,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final double radius;
  final bool outlined;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Clip clip;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius.r),
      side: outlined ? BorderSide(color: cs.outlineVariant) : BorderSide.none,
    );
    Widget body = padding == null ? child : Padding(padding: padding!, child: child);
    if (onTap != null || onLongPress != null) {
      body = InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        customBorder: shape,
        child: body,
      );
    }
    return Material(
      color: color ?? cs.surfaceContainerLowest,
      shape: shape,
      clipBehavior: clip,
      child: body,
    );
  }
}

/// 섹션 라벨 — 작은 굵은 글씨. 카드 제목이 아니라 목록의 "구역 이름"에 쓴다.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(4.w, 0, 4.w, 8.h),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
                color: cs.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// 아이콘을 담는 둥근 사각 배지. 목록 leading·다이얼로그 헤더에 공통 사용.
class IconBadge extends StatelessWidget {
  const IconBadge(
    this.icon, {
    super.key,
    this.size = 40,
    this.tone = IconBadgeTone.neutral,
  });

  final IconData icon;
  final double size;
  final IconBadgeTone tone;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (bg, fg) = switch (tone) {
      IconBadgeTone.neutral => (cs.surfaceContainerHigh, cs.onSurface),
      IconBadgeTone.primary => (cs.primaryContainer, cs.onPrimaryContainer),
      IconBadgeTone.accent => (cs.secondaryContainer, cs.onSecondaryContainer),
      IconBadgeTone.success => (cs.tertiaryContainer, cs.onTertiaryContainer),
      IconBadgeTone.danger => (cs.errorContainer, cs.onErrorContainer),
      IconBadgeTone.ink => (cs.onSurface, cs.surface),
    };
    return Container(
      width: size.r,
      height: size.r,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular((size * 0.3).r),
      ),
      child: Icon(icon, size: (size * 0.5).r, color: fg),
    );
  }
}

enum IconBadgeTone { neutral, primary, accent, success, danger, ink }

/// 앱 공통 확인 다이얼로그.
///
/// 상단 아이콘 배지 + 제목 + 본문 + 좌우 2버튼. 파괴적 액션은 [destructive]로
/// 확인 버튼을 error 톤으로 바꾼다.
class AppConfirmDialog extends StatelessWidget {
  const AppConfirmDialog({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    this.destructive = false,
    this.tone,
    this.onConfirm,
  });

  final IconData icon;
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool destructive;
  final IconBadgeTone? tone;
  final VoidCallback? onConfirm;

  static Future<bool?> show({
    required IconData icon,
    required String title,
    required String message,
    required String confirmLabel,
    required String cancelLabel,
    bool destructive = false,
    IconBadgeTone? tone,
    bool barrierDismissible = true,
    VoidCallback? onConfirm,
  }) {
    return Get.dialog<bool>(
      AppConfirmDialog(
        icon: icon,
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        destructive: destructive,
        tone: tone,
        onConfirm: onConfirm,
      ),
      barrierDismissible: barrierDismissible,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Dialog(
      backgroundColor: cs.surface,
      insetPadding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 24.h),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg.r),
        side: BorderSide(color: cs.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20.w, 22.h, 20.w, 16.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconBadge(
              icon,
              size: 44,
              tone:
                  tone ??
                  (destructive ? IconBadgeTone.danger : IconBadgeTone.primary),
            ),
            SizedBox(height: 14.h),
            Text(
              title,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                height: 1.25,
                color: cs.onSurface,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              message,
              style: TextStyle(
                fontSize: 14.sp,
                height: 1.4,
                color: cs.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 18.h),
            _DialogActions(
              cancelLabel: cancelLabel,
              confirmLabel: confirmLabel,
              destructive: destructive,
              cs: cs,
              onConfirm: onConfirm,
            ),
          ],
        ),
      ),
    );
  }
}

/// 확인 다이얼로그의 액션 버튼 두 개.
///
/// 기본은 [취소 | 확인] 가로 배치지만, 라벨이 길어 반폭 버튼 안에 들어가지
/// 않으면 세로로 쌓는다. 가로 배치를 고집하면 `Keep drawing`(en),
/// `Continuer à dessiner`(fr), `Continuar desenhando`(pt) 같은 라벨이
/// 360dp 화면에서 `Keep drawi…`로 잘려 무슨 버튼인지 알 수 없게 된다.
/// 세로로 쌓을 때는 Material 관례대로 확인 버튼을 위에 둔다.
class _DialogActions extends StatelessWidget {
  const _DialogActions({
    required this.cancelLabel,
    required this.confirmLabel,
    required this.destructive,
    required this.cs,
    this.onConfirm,
  });

  final String cancelLabel;
  final String confirmLabel;
  final bool destructive;
  final ColorScheme cs;
  final VoidCallback? onConfirm;

  /// 버튼 내부 좌우 패딩 + 여유. Material3 기본(24dp×2)에 약간의 안전 마진.
  static const double _buttonHorizontalPadding = 52;

  double _labelWidth(BuildContext context, String text) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: Theme.of(context).textTheme.labelLarge),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    return painter.width;
  }

  @override
  Widget build(BuildContext context) {
    final gap = 8.w;

    final cancelButton = OutlinedButton(
      onPressed: () => Get.back(result: false),
      child: Text(cancelLabel, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
    final confirmButton = FilledButton(
      style: destructive
          ? FilledButton.styleFrom(
              backgroundColor: cs.error,
              foregroundColor: cs.onError,
            )
          : null,
      onPressed: () {
        onConfirm?.call();
        Get.back(result: true);
      },
      child: Text(confirmLabel, maxLines: 1, overflow: TextOverflow.ellipsis),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final needed =
            _labelWidth(context, cancelLabel) +
            _labelWidth(context, confirmLabel) +
            _buttonHorizontalPadding * 2 +
            gap;
        final stacked =
            constraints.maxWidth.isFinite && needed > constraints.maxWidth;

        if (!stacked) {
          return Row(
            children: [
              Expanded(child: cancelButton),
              SizedBox(width: gap),
              Expanded(child: confirmButton),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            confirmButton,
            SizedBox(height: gap),
            cancelButton,
          ],
        );
      },
    );
  }
}

/// 바텀시트 공통 껍데기 — 그립 핸들 + 제목(+부제) + 내용.
class AppSheetShell extends StatelessWidget {
  const AppSheetShell({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.icon,
    this.scrollable = true,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget child;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 36.w,
            height: 4.h,
            margin: EdgeInsets.only(bottom: 14.h),
            decoration: BoxDecoration(
              color: cs.outlineVariant,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18.r, color: cs.onSurface),
              SizedBox(width: 8.w),
            ],
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  color: cs.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        if (subtitle != null) ...[
          SizedBox(height: 3.h),
          Text(
            subtitle!,
            style: TextStyle(fontSize: 13.sp, color: cs.onSurfaceVariant),
          ),
        ],
        SizedBox(height: 14.h),
        child,
      ],
    );

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusLg.r),
        ),
        border: Border(top: BorderSide(color: cs.outlineVariant)),
      ),
      padding: EdgeInsets.fromLTRB(18.w, 10.h, 18.w, 18.h),
      child: SafeArea(
        top: false,
        child: scrollable ? SingleChildScrollView(child: content) : content,
      ),
    );
  }
}

/// 목록 행 — 아이콘 배지 + 제목/부제 + trailing. 헤어라인 목록 안에서 쓴다.
class AppListRow extends StatelessWidget {
  const AppListRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.tone = IconBadgeTone.neutral,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final IconBadgeTone tone;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        child: Row(
          children: [
            IconBadge(icon, size: 36, tone: tone),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                  if (subtitle != null) ...[
                    SizedBox(height: 2.h),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 13.sp,
                        height: 1.3,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[SizedBox(width: 8.w), trailing!],
          ],
        ),
      ),
    );
  }
}

/// 방향(RTL) 대응 chevron.
class DirectionalChevron extends StatelessWidget {
  const DirectionalChevron({super.key, this.size = 18});

  final double size;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Icon(
      rtl ? LucideIcons.chevronLeft : LucideIcons.chevronRight,
      size: size.r,
      color: cs.outline,
    );
  }
}
