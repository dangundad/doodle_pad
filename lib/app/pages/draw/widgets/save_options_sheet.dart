import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:doodle_pad/app/controllers/setting_controller.dart';
import 'package:doodle_pad/app/services/export_service.dart';

/// 갤러리 저장 시 해상도/포맷을 선택하는 BottomSheet.
/// Design Ref: §5.2 — 마지막 선택은 SettingController에 persist.
class SaveOptionsSheet extends StatefulWidget {
  const SaveOptionsSheet({
    super.key,
    required this.initialResolution,
    required this.initialFormat,
    required this.onConfirm,
  });

  final int initialResolution; // 1 / 2 / 3
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
            'save_resolution_label'.tr,
            style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 6.h),
          _ResolutionPicker(
            current: _resolution,
            onChanged: (v) => setState(() => _resolution = v),
          ),
          SizedBox(height: 16.h),
          Text(
            'save_format_label'.tr,
            style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 6.h),
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

class _ResolutionPicker extends StatelessWidget {
  const _ResolutionPicker({required this.current, required this.onChanged});

  final int current;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [1, 2, 3].map((value) {
        final selected = current == value;
        return RadioListTile<int>(
          dense: true,
          contentPadding: EdgeInsets.zero,
          value: value,
          // ignore: deprecated_member_use — v3.32 RadioGroup 마이그레이션은 별도 작업.
          groupValue: current,
          // ignore: deprecated_member_use
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
          title: Text(
            value == 1
                ? 'save_resolution_1x'.tr
                : value == 2
                ? 'save_resolution_2x'.tr
                : 'save_resolution_3x'.tr,
            style: TextStyle(
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _FormatPicker extends StatelessWidget {
  const _FormatPicker({required this.current, required this.onChanged});

  final ExportImageFormat current;
  final ValueChanged<ExportImageFormat> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<ExportImageFormat>(
      segments: [
        ButtonSegment(
          value: ExportImageFormat.png,
          label: Text('save_format_png'.tr),
        ),
        ButtonSegment(
          value: ExportImageFormat.jpeg,
          label: Text('save_format_jpeg'.tr),
        ),
      ],
      selected: {current},
      onSelectionChanged: (s) {
        if (s.isNotEmpty) onChanged(s.first);
      },
    );
  }
}
