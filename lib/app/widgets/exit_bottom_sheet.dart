import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:doodle_pad/app/services/purchase_service.dart';
import 'package:doodle_pad/app/theme/app_theme.dart';
import 'package:doodle_pad/app/widgets/app_ui.dart';

class ExitBottomSheet extends StatelessWidget {
  const ExitBottomSheet({super.key});

  static Future<T?> show<T>() {
    if (Get.isBottomSheetOpen ?? false) {
      return Future<T?>.value();
    }

    return Get.bottomSheet<T>(
      const ExitBottomSheet(),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.34),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(12.w, 0, 12.w, 12.h),
        child: AppPanel(
          color: cs.surface,
          radius: AppTheme.radiusLg,
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const IconBadge(
                    LucideIcons.doorOpen,
                    size: 44,
                    tone: IconBadgeTone.primary,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'exit_confirmation'.tr,
                          style: TextStyle(
                            fontSize: 19.sp,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                            color: cs.onSurface,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'exit_app_message'.tr,
                          style: TextStyle(
                            fontSize: 14.sp,
                            height: 1.4,
                            color: cs.onSurfaceVariant,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (!PurchaseService.isPremiumActive) ...[
                SizedBox(height: 14.h),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 10.h,
                  ),
                  decoration: BoxDecoration(
                    color: cs.secondaryContainer,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm.r),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.crown,
                        size: 16.r,
                        color: cs.onSecondaryContainer,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'premium_subtitle'.tr,
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color: cs.onSecondaryContainer,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              SizedBox(height: 18.h),
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
                    child: FilledButton.icon(
                      // iOS는 HIG상 앱이 스스로 종료하면 안 되며 SystemNavigator.pop도
                      // 무시된다. iOS에서는 시트만 닫고, Android에서만 실제 종료한다.
                      onPressed: () {
                        if (defaultTargetPlatform == TargetPlatform.iOS) {
                          Get.back();
                          return;
                        }
                        SystemNavigator.pop();
                      },
                      icon: Icon(LucideIcons.logOut, size: 18.r),
                      label: Text('exit'.tr),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
