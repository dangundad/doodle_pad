import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:doodle_pad/app/admob/ads_banner.dart';
import 'package:doodle_pad/app/admob/ads_helper.dart';
import 'package:doodle_pad/app/controllers/setting_controller.dart';
import 'package:doodle_pad/app/routes/app_pages.dart';
import 'package:doodle_pad/app/theme/app_theme.dart';
import 'package:doodle_pad/app/utils/app_constants.dart';
import 'package:doodle_pad/app/utils/app_toast.dart';
import 'package:doodle_pad/app/widgets/app_ui.dart';

class SettingsPage extends GetView<SettingController> {
  const SettingsPage({super.key});

  /// supportedLocales(translate.dart)와 1:1로 매칭되는 사용자 표시 라벨(자국어 표기).
  /// translate_consistency_test 가 `Languages.supportedLocales` 와 일치 여부를 검증한다.
  static const Map<String, String> _languageOptions = {
    'en': 'English',
    'ko': '한국어',
    'ja': '日本語',
    'de': 'Deutsch',
    'ru': 'Русский',
    'fr': 'Français',
    'es': 'Español',
    'pt': 'Português',
    'id': 'Bahasa Indonesia',
    'zh': '中文',
    'ar': 'العربية',
  };

  @visibleForTesting
  static Map<String, String> get languageOptionsForTest =>
      Map.unmodifiable(_languageOptions);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _loc('settings', 'Settings'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      bottomNavigationBar: const AdBannerBar(),
      body: SafeArea(
        child: Obx(
          () => SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 프리미엄 진입 — 보조색(크레용 노랑) 배지로 목록과 구분.
                AppPanel(
                  color: cs.surfaceContainerLow,
                  onTap: () => Get.toNamed(Routes.PREMIUM),
                  padding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 14.h,
                  ),
                  child: Row(
                    children: [
                      // 왕관 글리프 대신 앱 마크(스프링 노트 낙서)를 쓴다.
                      // 프리미엄은 "이 앱을 응원한다"는 뜻이라 앱 자신이 주인공이다.
                      const AppIconMark(
                        size: 40,
                        asset: AppAssets.APP_MARK,
                        background: AppTheme.badgeCream,
                        inset: 0.08,
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _loc('premium_title', 'Premium'),
                              style: TextStyle(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w700,
                                color: cs.onSurface,
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              _loc(
                                'premium_subtitle',
                                'Unlock premium features',
                              ),
                              style: TextStyle(
                                fontSize: 13.sp,
                                height: 1.3,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const DirectionalChevron(),
                    ],
                  ),
                ),
                SizedBox(height: 22.h),
                SectionLabel(_loc('drawing_settings', 'Drawing settings')),
                AppPanel(
                  child: Column(
                    children: [
                      _SwitchRow(
                        value: controller.hapticEnabled.value,
                        title: _loc('haptic_feedback', 'Haptic feedback'),
                        subtitle: _loc(
                          'haptic_feedback_desc',
                          'Vibrate when interacting with tools',
                        ),
                        icon: LucideIcons.vibrate,
                        badgeColor: AppTheme.badgeGrape,
                        onChanged: controller.setHapticEnabled,
                      ),
                      const Divider(height: 1),
                      _SwitchRow(
                        value: controller.showBrushGuide.value,
                        title: _loc('show_brush_guide', 'Show brush guide'),
                        subtitle: _loc(
                          'show_brush_guide_desc',
                          'Show the brush hint below the drawing toolbar',
                        ),
                        icon: LucideIcons.lightbulb,
                        badgeColor: AppTheme.badgeTangerine,
                        onChanged: controller.setShowBrushGuide,
                      ),
                      const Divider(height: 1),
                      _SwitchRow(
                        value: controller.askBeforeClear.value,
                        title: _loc('ask_before_clear', 'Ask before clear'),
                        subtitle: _loc(
                          'ask_before_clear_desc',
                          'Confirm before deleting all strokes',
                        ),
                        icon: LucideIcons.eraser,
                        badgeColor: AppTheme.badgeCherry,
                        onChanged: controller.setAskBeforeClear,
                      ),
                      const Divider(height: 1),
                      _SwitchRow(
                        value: controller.shakeToClearEnabled.value,
                        title: _loc('shake_to_clear_title', 'Shake to clear'),
                        subtitle: _loc(
                          'shake_to_clear_desc',
                          'Shake the device to clear the canvas (always asks).',
                        ),
                        icon: LucideIcons.smartphone,
                        badgeColor: AppTheme.badgeSea,
                        onChanged: controller.setShakeToClearEnabled,
                      ),
                      const Divider(height: 1),
                      _LanguageRow(
                        value: controller.language.value,
                        options: _languageOptions,
                        onChanged: (value) {
                          if (value != null) {
                            controller.setLanguage(value);
                          }
                        },
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 22.h),
                SectionLabel(_loc('data_and_support', 'Data and support')),
                AppPanel(
                  child: Column(
                    children: [
                      AppListRow(
                        icon: LucideIcons.rotateCcw,
                        iconBackground: AppTheme.badgeTangerine,
                        title: _loc('clear_data', 'Clear local data'),
                        subtitle: _loc(
                          'clear_data_desc',
                          'Reset app preferences',
                        ),
                        trailing: const DirectionalChevron(),
                        onTap: _confirmAndClear,
                      ),
                      const Divider(height: 1),
                      AppListRow(
                        key: const ValueKey('settings-rate-app-tile'),
                        icon: LucideIcons.star,
                        iconBackground: AppTheme.badgeBerry,
                        title: _loc('rate_app', 'Rate app'),
                        subtitle: _loc(
                          'rate_app_desc',
                          'Leave a review on the store',
                        ),
                        trailing: const DirectionalChevron(),
                        onTap: controller.rateApp,
                      ),
                      const Divider(height: 1),
                      AppListRow(
                        key: const ValueKey('settings-more-apps-tile'),
                        icon: LucideIcons.layoutGrid,
                        iconBackground: AppTheme.badgeGrape,
                        title: _loc('more_apps', 'More apps'),
                        subtitle: _loc(
                          'more_apps_desc',
                          'Explore more apps from DangunDad',
                        ),
                        trailing: const DirectionalChevron(),
                        onTap: controller.openMoreApps,
                      ),
                      // UMP 개인정보 옵션. EEA/UK 처럼 동의 폼이 필요한 지역에서만
                      // 나타난다(구글 정책상 동의를 다시 바꿀 경로가 반드시 있어야 한다).
                      ValueListenableBuilder<bool>(
                        valueListenable: AdHelper.privacyOptionsRequired,
                        builder: (context, isRequired, _) {
                          if (!isRequired) return const SizedBox.shrink();
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Divider(height: 1),
                              AppListRow(
                                key: const ValueKey(
                                  'settings-privacy-choices-tile',
                                ),
                                icon: LucideIcons.shieldCheck,
                                iconBackground: AppTheme.badgeSea,
                                title: _loc(
                                  'privacy_choices',
                                  'Ad privacy choices',
                                ),
                                subtitle: _loc(
                                  'privacy_choices_desc',
                                  'Change your ad consent',
                                ),
                                trailing: const DirectionalChevron(),
                                onTap: () => unawaited(
                                  AdHelper.showPrivacyOptionsForm(),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const Divider(height: 1),
                      // 목록의 마지막은 앱 버전. 문의/버그 제보 때 사용자가 바로
                      // 확인할 수 있어야 해서 탭 동작 없이 값만 보여 준다.
                      AppListRow(
                        key: const ValueKey('settings-app-version-tile'),
                        icon: LucideIcons.info,
                        iconBackground: AppTheme.badgeSky,
                        title: _loc('app_version', 'App version'),
                        subtitle: controller.appVersion.value.isEmpty
                            ? null
                            : controller.appVersion.value,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmAndClear() async {
    final shouldClear = await AppConfirmDialog.show(
      icon: LucideIcons.rotateCcw,
      title: _loc('clear_data', 'Clear local data'),
      message: _loc(
        'clear_data_confirm',
        'This will reset local preferences. Continue?',
      ),
      confirmLabel: _loc('confirm', 'Confirm'),
      cancelLabel: _loc('cancel', 'Cancel'),
      destructive: true,
    );

    if (shouldClear != true) {
      return;
    }

    await controller.clearAppSettings();

    AppToast.show(
      AppToastMessage.success(
        title: _loc('clear_data', 'Clear local data'),
        description: _loc(
          'clear_data_complete',
          'Local data has been removed.',
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final bool value;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color badgeColor;
  final ValueChanged<bool> onChanged;

  const _SwitchRow({
    required this.value,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.badgeColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AppListRow(
      icon: icon,
      iconBackground: badgeColor,
      title: title,
      subtitle: subtitle,
      onTap: () => onChanged(!value),
      trailing: Switch(value: value, onChanged: onChanged),
    );
  }
}

/// 언어 선택 행.
///
/// 예전에는 지원 언어 11개를 ChoiceChip `Wrap` 으로 전부 펼쳐, 설정 목록에서
/// 이 항목 하나가 네댓 줄(다른 행의 4배 높이)을 차지했다. 안드로이드 설정
/// 관례대로 제목 아래에 "현재 언어"만 요약으로 두고, 행을 누르면 드롭다운
/// 메뉴에서 고른다. 현재 언어를 trailing 이 아니라 subtitle 에 두는 이유는
/// `Bahasa Indonesia` 같은 긴 이름이 320dp·130% 배율에서 제목과 충돌하지
/// 않게 하기 위해서다(다른 행과 높이도 같아진다).
class _LanguageRow extends StatelessWidget {
  final String value;
  final Map<String, String> options;
  final ValueChanged<String?> onChanged;

  const _LanguageRow({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  Future<void> _openMenu(BuildContext context) async {
    final cs = Theme.of(context).colorScheme;
    final row = context.findRenderObject() as RenderBox?;
    final overlay =
        Navigator.of(context).overlay?.context.findRenderObject() as RenderBox?;
    if (row == null || overlay == null || !row.hasSize) return;

    // 행 바로 아래에서 열리도록 행의 사각형을 오버레이 좌표로 환산한다.
    final topLeft = row.localToGlobal(Offset.zero, ancestor: overlay);
    final bottomRight = row.localToGlobal(
      row.size.bottomRight(Offset.zero),
      ancestor: overlay,
    );
    final position = RelativeRect.fromLTRB(
      topLeft.dx,
      bottomRight.dy - 12.h,
      overlay.size.width - bottomRight.dx,
      overlay.size.height - bottomRight.dy,
    );

    final selected = await showMenu<String>(
      context: context,
      position: position,
      initialValue: options.containsKey(value) ? value : null,
      color: cs.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 3,
      // 11개를 한 번에 펼치면 화면을 거의 다 덮어 드롭다운으로 보이지 않는다.
      // 높이를 제한해 행 근처에 붙이고, 나머지는 메뉴 안에서 스크롤한다.
      constraints: BoxConstraints(
        minWidth: 200.w,
        maxWidth: 280.w,
        maxHeight: 330.h,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd.r),
        side: BorderSide(color: cs.outlineVariant),
      ),
      items: [
        for (final entry in options.entries)
          PopupMenuItem<String>(
            value: entry.key,
            child: _LanguageMenuItem(
              label: entry.value,
              selected: entry.key == value,
            ),
          ),
      ],
    );

    if (selected != null) {
      onChanged(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AppListRow(
      key: const ValueKey('settings-language-tile'),
      icon: LucideIcons.languages,
      iconBackground: AppTheme.badgeInk,
      title: _loc('language', 'Language'),
      subtitle: options[value] ?? value,
      onTap: () => _openMenu(context),
      trailing: Icon(LucideIcons.chevronDown, size: 18.r, color: cs.outline),
    );
  }
}

/// 언어 드롭다운의 한 줄. 선택된 언어만 잉크색 + 체크로 표시한다.
class _LanguageMenuItem extends StatelessWidget {
  final String label;
  final bool selected;

  const _LanguageMenuItem({required this.label, required this.selected});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? cs.primary : cs.onSurface,
            ),
          ),
        ),
        if (selected) ...[
          SizedBox(width: 10.w),
          Icon(LucideIcons.check, size: 16.r, color: cs.primary),
        ],
      ],
    );
  }
}

String _loc(String key, String fallback) {
  final translated = key.tr;
  return translated == key ? fallback : translated;
}
