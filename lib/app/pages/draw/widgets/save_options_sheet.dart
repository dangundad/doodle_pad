import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:doodle_pad/app/controllers/setting_controller.dart';
import 'package:doodle_pad/app/services/export_service.dart';

/// 갤러리 저장 시 포맷을 선택하는 BottomSheet.
/// Design Ref: §5.2 — 마지막 선택은 SettingController에 persist.
class SaveOptionsSheet extends StatefulWidget {
  const SaveOptionsSheet({
    super.key,
    required this.initialResolution,
    required this.initialFormat,
    required this.onConfirm,
  });

  final int initialResolution; // controller persisted (UI hidden)
  final ExportImageFormat initialFormat;

  /// 사용자가 "저장" 누르면 호출. 시트 닫힘은 호출자가 책임진다.
  final void Function(int resolution, ExportImageFormat format) onConfirm;

  /// 헬퍼: SettingController에서 마지막 선택을 읽어 시트를 띄운다.
  /// 호출 측에서는 결과를 wait할 필요가 없다 — onConfirm 콜백으로 처리.
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
  late ExportImageFormat _format;

  @override
  void initState() {
    super.initState();
    _format = widget.initialFormat;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Get.theme.colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 24.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.download, size: 18.r, color: cs.primary),
              SizedBox(width: 8.w),
              Text(
                'save_to_gallery_title'.tr,
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Text(
            'save_to_gallery_desc'.tr,
            style: TextStyle(fontSize: 12.sp, color: cs.onSurfaceVariant),
          ),
          SizedBox(height: 16.h),
          Text(
            'save_format_label'.tr,
            style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 8.h),
          _FormatPicker(
            current: _format,
            onChanged: (f) => setState(() => _format = f),
          ),
          SizedBox(height: 20.h),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: Get.back,
                  child: Text('cancel'.tr),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: FilledButton.icon(
                  icon: Icon(LucideIcons.download, size: 16.r),
                  label: Text('save'.tr),
                  onPressed: () {
                    widget.onConfirm(widget.initialResolution, _format);
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

/// 포맷 선택: 두 버튼이 바텀시트 가로폭을 균등 분할해 채운다.
/// Design Ref: §5.2 — 큰 탭 타깃으로 한 손 조작 시 오선택을 줄인다.
class _FormatPicker extends StatelessWidget {
  const _FormatPicker({required this.current, required this.onChanged});

  final ExportImageFormat current;
  final ValueChanged<ExportImageFormat> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _FormatOption(
            label: 'save_format_png'.tr,
            icon: LucideIcons.fileImage,
            selected: current == ExportImageFormat.png,
            onTap: () => onChanged(ExportImageFormat.png),
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: _FormatOption(
            label: 'save_format_jpeg'.tr,
            icon: LucideIcons.image,
            selected: current == ExportImageFormat.jpeg,
            onTap: () => onChanged(ExportImageFormat.jpeg),
          ),
        ),
      ],
    );
  }
}

class _FormatOption extends StatelessWidget {
  const _FormatOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Get.theme.colorScheme;
    return Material(
      color: selected ? cs.primaryContainer : cs.surfaceContainerLow,
      borderRadius: BorderRadius.circular(14.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(14.r),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(
              color: selected ? cs.primary : cs.outlineVariant,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18.r,
                color: selected ? cs.primary : cs.onSurfaceVariant,
              ),
              SizedBox(width: 8.w),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: selected ? cs.onPrimaryContainer : cs.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
