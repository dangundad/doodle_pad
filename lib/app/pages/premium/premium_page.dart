import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:doodle_pad/app/controllers/premium_controller.dart';
import 'package:doodle_pad/app/services/purchase_service.dart';

class PremiumPage extends GetView<PremiumController> {
  const PremiumPage({super.key});

  @override
  Widget build(BuildContext context) {
    final service = PurchaseService.to;
    final cs = Get.theme.colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                cs.surface,
                cs.surfaceContainerLowest.withValues(alpha: 0.95),
                cs.surfaceContainerLow.withValues(alpha: 0.9),
              ],
            ),
          ),
          child: Obx(
            () => service.isPremium.value
                ? _buildOwnedView(context, cs)
                : _buildUpgradeView(context, cs, service),
          ),
        ),
      ),
    );
  }

  Widget _buildUpgradeView(
    BuildContext context,
    ColorScheme cs,
    PurchaseService service,
  ) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(18.w),
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'premium_title'.tr,
            style: TextStyle(
              fontSize: 30.sp,
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'premium_subtitle'.tr,
            style: TextStyle(
              color: cs.onSurfaceVariant,
              height: 1.35,
              fontSize: 13.sp,
            ),
          ),
          SizedBox(height: 18.h),
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLow,
              borderRadius: BorderRadius.circular(18.r),
              border: Border.all(color: cs.outline.withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(
                  color: cs.shadow.withValues(alpha: 0.08),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 52.r,
                  height: 52.r,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16.r),
                    gradient: LinearGradient(
                      colors: [cs.primary, cs.primary.withValues(alpha: 0.64)],
                    ),
                  ),
                  child: Icon(
                    Icons.workspace_premium,
                    size: 26.r,
                    color: cs.onPrimary,
                  ),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'premium_title'.tr,
                        style: TextStyle(
                          fontSize: 17.sp,
                          fontWeight: FontWeight.w800,
                          color: cs.onSurface,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'premium_subtitle'.tr,
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: cs.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 18.h),
          _BenefitsCard(cs: cs),
          SizedBox(height: 14.h),
          _PlansSection(
            controller: controller,
            cs: cs,
            purchaseService: service,
          ),
          SizedBox(height: 16.h),
          Obx(
            () => SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: service.isLoading.value ? null : controller.purchase,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                ),
                child: service.isLoading.value
                    ? SizedBox(width: 20.w,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text('premium_purchase'.tr),
              ),
            ),
          ),
          SizedBox(height: 10.h),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: service.isLoading.value ? null : controller.restore,
              child: Text('premium_restore'.tr),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'premium_purchase_note'.tr,
            style: TextStyle(
              color: cs.onSurfaceVariant,
              fontSize: 11.sp,
              height: 1.35,
            ),
          ),
          SizedBox(height: 24.h),
        ],
      ),
    );
  }

  Widget _buildOwnedView(BuildContext context, ColorScheme cs) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Container(
          padding: EdgeInsets.all(24.w),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(22.r),
            border: Border.all(color: cs.outline.withValues(alpha: 0.35)),
            boxShadow: [
              BoxShadow(
                color: cs.shadow.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.workspace_premium, size: 60.r, color: cs.primary),
              SizedBox(height: 14.h),
              Text(
                'premium_owned'.tr,
                style: TextStyle(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                'premium_ready'.tr,
                style: TextStyle(color: cs.onSurfaceVariant, height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BenefitsCard extends StatelessWidget {
  final ColorScheme cs;

  const _BenefitsCard({required this.cs});

  @override
  Widget build(BuildContext context) {
    final benefits = [
      'premium_benefit_remove_ads'.tr,
      'premium_benefit_unlimited'.tr,
      'premium_benefit_statistics'.tr,
    ];

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: cs.outline.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'premium_benefits'.tr,
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
            ),
          ),
          SizedBox(height: 12.h),
          for (final benefit in benefits)
            Padding(
              padding: EdgeInsets.only(bottom: 9.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.verified_rounded, size: 16.r, color: cs.primary),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      benefit,
                      style: TextStyle(fontSize: 12.sp, color: cs.onSurface),
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

class _PlansSection extends StatelessWidget {
  final PremiumController controller;
  final ColorScheme cs;
  final PurchaseService purchaseService;

  const _PlansSection({
    required this.controller,
    required this.cs,
    required this.purchaseService,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(color: cs.outline.withValues(alpha: 0.35)),
        ),
        padding: EdgeInsets.all(14.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'premium_plan_title'.tr,
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w800,
                color: cs.onSurface,
              ),
            ),
            SizedBox(height: 12.h),
            ...controller.plans.asMap().entries.map((entry) {
              final index = entry.key;
              final plan = entry.value;
              final isSelected = controller.selectedPlanIndex.value == index;
              final price = controller.planPrice(index);
              final isLoading = purchaseService.isLoading.value;

              return GestureDetector(
                onTap: isLoading ? null : () => controller.selectPlan(index),
                child: Container(
                  margin: EdgeInsets.only(bottom: 10.h),
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? cs.primaryContainer.withValues(alpha: 0.32)
                        : cs.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: isSelected ? cs.primary : cs.outline,
                      width: isSelected ? 1.8 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: cs.primary,
                        size: 16.r,
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              plan.title,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13.sp,
                                color: cs.onSurface,
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              plan.description,
                              style: TextStyle(
                                color: cs.onSurfaceVariant,
                                fontSize: 11.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        price,
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: cs.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
