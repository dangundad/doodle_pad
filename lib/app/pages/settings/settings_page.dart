import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:doodle_pad/app/controllers/setting_controller.dart';
import 'package:doodle_pad/app/routes/app_pages.dart';
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
                      const IconBadge(
                        LucideIcons.crown,
                        tone: IconBadgeTone.accent,
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
                        key: const ValueKey('settings-send-feedback-tile'),
                        icon: LucideIcons.messageSquare,
                        title: _loc('feedback', 'Send feedback'),
                        subtitle: _loc(
                          'feedback_desc',
                          'Share your improvement ideas',
                        ),
                        trailing: const DirectionalChevron(),
                        onTap: controller.sendFeedback,
                      ),
                      const Divider(height: 1),
                      AppListRow(
                        key: const ValueKey('settings-rate-app-tile'),
                        icon: LucideIcons.star,
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
                        title: _loc('more_apps', 'More apps'),
                        subtitle: _loc(
                          'more_apps_desc',
                          'Explore more apps from DangunDad',
                        ),
                        trailing: const DirectionalChevron(),
                        onTap: controller.openMoreApps,
                      ),
                      const Divider(height: 1),
                      AppListRow(
                        key: const ValueKey('settings-privacy-policy-tile'),
                        icon: LucideIcons.shield,
                        title: _loc('privacy_policy', 'Privacy policy'),
                        subtitle: _loc(
                          'privacy_policy_desc',
                          'Read how local data and permissions are handled',
                        ),
                        trailing: const DirectionalChevron(),
                        onTap: controller.openPrivacyPolicy,
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
  final ValueChanged<bool> onChanged;

  const _SwitchRow({
    required this.value,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AppListRow(
      icon: icon,
      title: title,
      subtitle: subtitle,
      onTap: () => onChanged(!value),
      trailing: Switch(value: value, onChanged: onChanged),
    );
  }
}

class _LanguageRow extends StatelessWidget {
  final String value;
  final Map<String, String> options;
  final ValueChanged<String?> onChanged;

  const _LanguageRow({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 14.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const IconBadge(LucideIcons.languages, size: 36),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  _loc('language', 'Language'),
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: options.entries
                .map(
                  (entry) => ChoiceChip(
                    label: Text(
                      entry.value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    showCheckmark: false,
                    selected: value == entry.key,
                    onSelected: (selected) {
                      if (selected) {
                        onChanged(entry.key);
                      }
                    },
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

String _loc(String key, String fallback) {
  final translated = key.tr;
  return translated == key ? fallback : translated;
}
