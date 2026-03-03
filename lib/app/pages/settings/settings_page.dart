import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:doodle_pad/app/controllers/setting_controller.dart';
import 'package:doodle_pad/app/routes/app_pages.dart';

class SettingsPage extends GetView<SettingController> {
  const SettingsPage({super.key});

  static const Map<String, String> _languageOptions = {
    'en': 'English',
    'ko': '한국어',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_loc('settings', 'Settings')),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: Container(
            height: 3,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Get.theme.colorScheme.primary,
                  Get.theme.colorScheme.tertiary,
                ],
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Obx(
          () => ListView(
            padding: EdgeInsets.all(16.w),
            children: [
              _SettingsSection(
                title: _loc('quick_actions', 'Quick actions'),
                icon: Icons.dashboard_customize,
                children: [
                  _ListItem(
                    icon: Icons.history,
                    title: _loc('open_history', 'Open history'),
                    subtitle: _loc(
                      'open_history_desc',
                      'Check previous drawings and activity',
                    ),
                    onTap: () {
                      _track('open_history', 'settings');
                      Get.toNamed(Routes.HISTORY);
                    },
                  ),
                  _ListItem(
                    icon: Icons.bar_chart,
                    title: _loc('open_stats', 'Open stats'),
                    subtitle: _loc(
                      'open_stats_desc',
                      'Review drawing usage and totals',
                    ),
                    onTap: () {
                      _track('open_stats', 'settings');
                      Get.toNamed(Routes.STATS);
                    },
                  ),
                  _ListItem(
                    icon: Icons.auto_awesome,
                    title: _loc('premium_title', 'Premium'),
                    subtitle: _loc(
                      'premium_subtitle',
                      'Unlock premium features',
                    ),
                    onTap: () {
                      _track('open_premium', 'settings');
                      Get.toNamed(Routes.PREMIUM);
                    },
                  ),
                ],
              ),
              SizedBox(height: 14.h),
              _SettingsSection(
                title: _loc('drawing_settings', 'Drawing settings'),
                icon: Icons.draw,
                children: [
                  _BuildSwitchTile(
                    value: controller.hapticEnabled.value,
                    title: _loc('haptic_feedback', 'Haptic feedback'),
                    subtitle: _loc(
                      'haptic_feedback_desc',
                      'Vibrate when interacting with tools',
                    ),
                    icon: Icons.vibration,
                    onChanged: controller.setHapticEnabled,
                  ),
                  _BuildSwitchTile(
                    value: controller.showBrushGuide.value,
                    title: _loc('show_brush_guide', 'Show brush guide'),
                    subtitle: _loc(
                      'show_brush_guide_desc',
                      'Show first-launch guide popup on app startup',
                    ),
                    icon: Icons.tips_and_updates,
                    onChanged: controller.setShowBrushGuide,
                  ),
                  _BuildSwitchTile(
                    value: controller.askBeforeClear.value,
                    title: _loc('ask_before_clear', 'Ask before clear'),
                    subtitle: _loc(
                      'ask_before_clear_desc',
                      'Confirm before deleting all strokes',
                    ),
                    icon: Icons.clear,
                    onChanged: controller.setAskBeforeClear,
                  ),
                  _BuildLanguageTile(
                    value: controller.language.value,
                    options: _languageOptions,
                    onChanged: (value) {
                      if (value != null) {
                        controller.setLanguage(value);
                        _track(
                          'change_language',
                          'settings',
                          metadata: {'language': value},
                        );
                      }
                    },
                  ),
                ],
              ),
              SizedBox(height: 14.h),
              _SettingsSection(
                title: _loc('data_and_support', 'Data and support'),
                icon: Icons.cleaning_services,
                children: [
                  _ListItem(
                    icon: Icons.delete_outline,
                    title: _loc('clear_data', 'Clear local data'),
                    subtitle: _loc(
                      'clear_data_desc',
                      'Reset app preferences and usage history',
                    ),
                    onTap: () => _confirmAndClear(),
                  ),
                  _ListItem(
                    icon: Icons.feedback,
                    title: _loc('feedback', 'Send feedback'),
                    subtitle: _loc(
                      'feedback_desc',
                      'Share your improvement ideas',
                    ),
                    onTap: () {
                      _track('open_feedback', 'settings');
                      Get.snackbar(
                        _loc('feedback', 'Send feedback'),
                        _loc(
                          'feedback_tip',
                          'Feature is planned. Thank you for waiting.',
                        ),
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor:
                            Get.theme.colorScheme.surfaceContainerHigh,
                        colorText: Get.theme.colorScheme.onSurface,
                        duration: const Duration(seconds: 2),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmAndClear() async {
    final shouldClear = await Get.dialog<bool>(
      AlertDialog(
        title: Text(_loc('clear_data', 'Clear local data')),
        content: Text(
          _loc(
            'clear_data_confirm',
            'This will reset local preferences and usage logs. Continue?',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text(_loc('cancel', 'Cancel')),
          ),
          FilledButton(
            onPressed: () => Get.back(result: true),
            child: Text(_loc('confirm', 'Confirm')),
          ),
        ],
      ),
    );

    if (shouldClear != true) {
      return;
    }

    controller.logEvent('clear_local_data', 'settings');
    await controller.clearAppSettings();

    Get.snackbar(
      _loc('clear_data', 'Clear local data'),
      _loc('clear_data_complete', 'Local data has been removed.'),
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Get.theme.colorScheme.surfaceContainerHigh,
      colorText: Get.theme.colorScheme.onSurface,
      duration: const Duration(seconds: 2),
    );
  }

  void _track(
    String eventName,
    String screen, {
    Map<String, dynamic>? metadata,
  }) {
    controller.logEvent(eventName, screen, metadata: metadata ?? const {});
  }
}

class _BuildLanguageTile extends StatelessWidget {
  final String value;
  final Map<String, String> options;
  final ValueChanged<String?> onChanged;

  const _BuildLanguageTile({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Get.theme.colorScheme;

    return ListTile(
      leading: Icon(Icons.language, color: cs.primary),
      title: Text(_loc('language', 'Language')),
      subtitle: Padding(
        padding: EdgeInsets.only(top: 8.h),
        child: Wrap(
          spacing: 8.w,
          children: options.entries
              .map(
                (entry) => ChoiceChip(
                  label: Text(entry.value),
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
      ),
    );
  }
}

class _BuildSwitchTile extends StatelessWidget {
  final bool value;
  final String title;
  final String subtitle;
  final IconData icon;
  final ValueChanged<bool> onChanged;

  const _BuildSwitchTile({
    required this.value,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Get.theme.colorScheme;

    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      secondary: Icon(icon, color: cs.primary),
      title: Text(title),
      subtitle: Text(subtitle),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Get.theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: cs.outline.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(14.w, 12.h, 12.w, 10.h),
            child: Row(
              children: [
                Icon(icon, size: 18.r, color: cs.primary),
                SizedBox(width: 8.w),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15.sp,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }
}

class _ListItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ListItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Get.theme.colorScheme;

    return ListTile(
      leading: Icon(icon, color: cs.primary),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

String _loc(String key, String fallback) {
  final translated = key.tr;
  return translated == key ? fallback : translated;
}
