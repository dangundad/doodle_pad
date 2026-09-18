import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:doodle_pad/app/admob/ads_native.dart';
import 'package:doodle_pad/app/routes/app_pages.dart';
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
        // 네이티브 고급(medium) 광고는 320~400dp 까지 자라므로, 작은 화면이나
        // 130% 글꼴에서 시트가 화면을 넘길 수 있다. 시트 전체(패널 패딩 포함)를
        // 화면의 80% 로 묶고 넘치는 만큼만 스크롤한다.
        // ⚠️ ConstrainedBox 는 반드시 AppPanel **바깥**에 둔다. 안에 두면 패널
        // 패딩(40dp)과 바깥 여백이 상한에 더해져 결국 화면을 넘긴다.
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.8,
          ),
          child: AppPanel(
            color: cs.surface,
            radius: AppTheme.radiusLg,
            padding: EdgeInsets.all(20.w),
            child: SingleChildScrollView(
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
                    // 안내만 하고 누를 수 없던 배너(실기기 QA). 탭하면 프리미엄으로 간다.
                    Material(
                      color: cs.secondaryContainer,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm.r),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusSm.r,
                        ),
                        onTap: () {
                          Get.back();
                          Get.toNamed(Routes.PREMIUM);
                        },
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 10.h,
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
                              Icon(
                                LucideIcons.chevronRight,
                                size: 16.r,
                                color: cs.onSecondaryContainer,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                  // 종료 시트는 사용자가 이미 작업을 마친 자리다. 네이티브 고급 광고는
                  // 여기에만 둔다(캔버스/작업 흐름에는 넣지 않는다).
                  // NativeAdWidget 이 프리미엄/동의/로드 실패를 스스로 가드하고,
                  // 로드 전에는 공간을 예약하지 않으므로 바깥 조건 없이 그대로 둔다.
                  Center(
                    child: NativeAdWidget(
                      templateType: TemplateType.medium,
                      // 광고가 없으면 여백까지 함께 접힌다.
                      padding: EdgeInsets.only(top: 16.h),
                    ),
                  ),
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
        ),
      ),
    );
  }
}
