import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:doodle_pad/app/controllers/setting_controller.dart';
import 'package:doodle_pad/app/services/export_service.dart';
import 'package:doodle_pad/app/theme/app_theme.dart';
import 'package:doodle_pad/app/widgets/app_ui.dart';

/// 갤러리 저장 시 해상도(1x/2x/3x)와 포맷(PNG/JPEG)을 선택하는 BottomSheet.
/// 마지막 선택은 SettingController에 persist.
class SaveOptionsSheet extends StatefulWidget {
  const SaveOptionsSheet({
    super.key,
    required this.initialResolution,
    required this.initialFormat,
    required this.onConfirm,
  });

  final int initialResolution;
  final ExportImageFormat initialFormat;

  /// 사용자가 "저장" 누르면 호출. 시트 닫힘은 호출자가 책임진다.
  final void Function(int resolution, ExportImageFormat format) onConfirm;

  static Future<void> show({
    required BuildContext context,
    required SettingController settingCtrl,
    required void Function(int resolution, ExportImageFormat format) onConfirm,
  }) {
    final initialFormat = settingCtrl.lastExportFormat.value == 'jpeg'
        ? ExportImageFormat.jpeg
        : ExportImageFormat.png;

    return Get.bottomSheet(
      SaveOptionsSheet(
        initialResolution: settingCtrl.lastExportResolution.value,
        initialFormat: initialFormat,
        onConfirm: onConfirm,
      ),
      isScrollControlled: false,
    );
  }

  @override
  State<SaveOptionsSheet> createState() => _SaveOptionsSheetState();
}

class _SaveOptionsSheetState extends State<SaveOptionsSheet> {
  late int _resolution;
  late ExportImageFormat _format;

  @override
  void initState() {
    super.initState();
    _resolution = widget.initialResolution;
    _format = widget.initialFormat;
  }

  @override
  Widget build(BuildContext context) {
    return AppSheetShell(
      icon: LucideIcons.download,
      title: 'save_to_gallery_title'.tr,
      subtitle: 'save_to_gallery_desc'.tr,
      scrollable: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel('save_resolution_label'.tr),
          _ResolutionPicker(
            current: _resolution,
            onChanged: (r) => setState(() => _resolution = r),
          ),
          SizedBox(height: 16.h),
          SectionLabel('save_format_label'.tr),
          _FormatPicker(
            current: _format,
            onChanged: (f) => setState(() => _format = f),
          ),
          SizedBox(height: 20.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: Get.back,
                  child: Text('cancel'.tr),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  icon: Icon(LucideIcons.download, size: 16.r),
                  label: Text('save'.tr),
                  onPressed: () {
                    widget.onConfirm(_resolution, _format);
                    Get.back();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 해상도 선택: 1x / 2x / 3x 가로 균등 분할.
/// 배수는 언어 공통이라 코드에서 그리고, 번역 키에는 화질 이름만 담는다.
class _ResolutionPicker extends StatelessWidget {
  const _ResolutionPicker({required this.current, required this.onChanged});

  final int current;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final value in const [1, 2, 3]) ...[
          if (value != 1) SizedBox(width: 8.w),
          Expanded(
            child: _OptionTile(
              selected: current == value,
              onTap: () => onChanged(value),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${value}x',
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                      color: _fg(context, current == value),
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'save_resolution_${value}x'.tr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11.sp,
                      height: 1.1,
                      color: current == value
                          ? _fg(context, true)
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// 포맷 선택: 두 버튼이 시트 가로폭을 균등 분할한다.
class _FormatPicker extends StatelessWidget {
  const _FormatPicker({required this.current, required this.onChanged});

  final ExportImageFormat current;
  final ValueChanged<ExportImageFormat> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget option(ExportImageFormat f, IconData icon, String label) {
      final selected = current == f;
      return Expanded(
        child: _OptionTile(
          selected: selected,
          onTap: () => onChanged(f),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18.r, color: _fg(context, selected)),
              SizedBox(width: 8.w),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: _fg(context, selected),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        option(ExportImageFormat.png, LucideIcons.fileImage, 'save_format_png'.tr),
        SizedBox(width: 8.w),
        option(ExportImageFormat.jpeg, LucideIcons.image, 'save_format_jpeg'.tr),
      ],
    );
  }
}

/// 선택형 타일 — 선택 시 잉크색 테두리 + 옅은 primaryContainer 배경.
/// primaryContainer 위 전경은 onPrimaryContainer 규칙을 지킨다.
class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.selected,
    required this.onTap,
    required this.child,
  });

  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppTheme.radiusSm.r),
      side: BorderSide(
        color: selected ? cs.primary : cs.outlineVariant,
        width: selected ? 2 : 1,
      ),
    );
    return Material(
      color: selected ? cs.primaryContainer : cs.surfaceContainerLowest,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        customBorder: shape,
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 12.h),
          child: child,
        ),
      ),
    );
  }
}

Color _fg(BuildContext context, bool selected) {
  final cs = Theme.of(context).colorScheme;
  return selected ? cs.onPrimaryContainer : cs.onSurface;
}
