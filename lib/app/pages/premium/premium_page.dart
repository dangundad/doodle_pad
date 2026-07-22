import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:doodle_pad/app/controllers/premium_controller.dart';
import 'package:doodle_pad/app/services/purchase_service.dart';

const _supportIcons = <IconData>[
  LucideIcons.coffee,
  LucideIcons.sandwich,
  LucideIcons.utensils,
];

class PremiumPage extends GetView<PremiumController> {
  const PremiumPage({super.key});

  @override
  Widget build(BuildContext context) {
    final service = PurchaseService.to;
    final cs = Get.theme.colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: Text('premium_title'.tr),
        centerTitle: true,
        actions: [
          Obx(
            () => IconButton(
              tooltip: 'premium_restore'.tr,
              onPressed: service.isLoading.value ? null : controller.restore,
              icon: const Icon(LucideIcons.rotateCcw),
            ),
          ),
        ],
      ),
      body: Obx(
        () => service.isPremium.value
            ? _OwnedPremiumView(cs: cs)
            : _UpgradeContent(controller: controller, service: service, cs: cs),
      ),
      bottomNavigationBar: Obx(
        () => service.isPremium.value
            ? const SizedBox.shrink()
            : _PurchaseBar(controller: controller, service: service, cs: cs),
      ),
    );
  }
}

class _UpgradeContent extends StatelessWidget {
  const _UpgradeContent({
    required this.controller,
    required this.service,
    required this.cs,
  });

  final PremiumController controller;
  final PurchaseService service;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(18.w, 10.h, 18.w, 24.h),
      children: [
        _HeroPanel(cs: cs),
        SizedBox(height: 16.h),
        _BenefitRow(cs: cs),
        SizedBox(height: 18.h),
        Text(
          'premium_plan_title'.tr,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w800,
            color: cs.onSurface,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: 10.h),
        Obx(
          () => Column(
            children: controller.plans.asMap().entries.map((entry) {
              final index = entry.key;
              final plan = entry.value;
              final isSelected = controller.selectedPlanIndex.value == index;

              return Padding(
                padding: EdgeInsets.only(bottom: 10.h),
                child: _SupportOptionTile(
                  key: ValueKey('premium_option_$index'),
                  plan: plan,
                  icon: _supportIcons[index],
                  price: controller.planPrice(index),
                  selected: isSelected,
                  enabled: !service.isLoading.value,
                  cs: cs,
                  onTap: () => controller.selectPlan(index),
                ),
              );
            }).toList(),
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          'premium_purchase_note'.tr,
          style: TextStyle(
            color: cs.onSurfaceVariant,
            fontSize: 14.sp,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({required this.cs});

  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: cs.primary.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 54.r,
            height: 54.r,
            decoration: BoxDecoration(
              color: cs.primary,
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Icon(
              LucideIcons.heartHandshake,
              color: cs.onPrimary,
              size: 28.r,
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'premium_support_title'.tr,
                  style: TextStyle(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w900,
                    color: cs.onPrimaryContainer,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  'premium_subtitle'.tr,
                  style: TextStyle(
                    fontSize: 14.sp,
                    height: 1.35,
                    color: cs.onSurfaceVariant,
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

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({required this.cs});

  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final items = [
      (LucideIcons.badgeCheck, 'premium_benefit_remove_ads'.tr),
      (LucideIcons.paintbrush, 'premium_benefit_premium_brushes'.tr),
      (LucideIcons.heart, 'premium_benefit_one_time_support'.tr),
    ];

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: cs.outline.withValues(alpha: 0.28)),
      ),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
              child: Row(
                children: [
                  Icon(items[i].$1, color: cs.primary, size: 20.r),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      items[i].$2,
                      style: TextStyle(
                        fontSize: 14.sp,
                        height: 1.3,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (i < items.length - 1)
              Divider(height: 1, color: cs.outlineVariant),
          ],
        ],
      ),
    );
  }
}

class _SupportOptionTile extends StatelessWidget {
  const _SupportOptionTile({
    super.key,
    required this.plan,
    required this.icon,
    required this.price,
    required this.selected,
    required this.enabled,
    required this.cs,
    required this.onTap,
  });

  final PremiumPlan plan;
  final IconData icon;
  final String price;
  final bool selected;
  final bool enabled;
  final ColorScheme cs;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final badge = plan.badge;

    return Material(
      color: selected
          ? cs.primaryContainer.withValues(alpha: 0.46)
          : cs.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(18.r),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(18.r),
        child: Container(
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(
              color: selected ? cs.primary : cs.outline.withValues(alpha: 0.32),
              width: selected ? 1.8 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 46.r,
                height: 46.r,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected
                      ? cs.primary.withValues(alpha: 0.14)
                      : cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Icon(icon, size: 23.r, color: cs.primary),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            plan.title,
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w800,
                              color: cs.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Text(
                          price,
                          style: TextStyle(
                            fontSize: 15.sp,
                            color: cs.primary,
                            fontWeight: FontWeight.w900,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    if (badge != null) ...[
                      SizedBox(height: 5.h),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 3.h,
                        ),
                        decoration: BoxDecoration(
                          color: cs.primary,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(
                            color: cs.onPrimary,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w800,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                    SizedBox(height: 4.h),
                    Text(
                      plan.description,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 10.w),
              Icon(
                selected ? LucideIcons.check : LucideIcons.circle,
                color: selected ? cs.primary : cs.outline,
                size: 19.r,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PurchaseBar extends StatelessWidget {
  const _PurchaseBar({
    required this.controller,
    required this.service,
    required this.cs,
  });

  final PremiumController controller;
  final PurchaseService service;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        key: const ValueKey('premium_purchase_bar'),
        padding: EdgeInsets.fromLTRB(18.w, 12.h, 18.w, 14.h),
        decoration: BoxDecoration(
          color: cs.surface,
          border: Border(top: BorderSide(color: cs.outlineVariant)),
          boxShadow: [
            BoxShadow(
              color: cs.shadow.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Obx(() {
              final plan = controller.plans[controller.selectedPlanIndex.value];
              final price = controller.planPrice(
                controller.selectedPlanIndex.value,
              );

              return Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  '${plan.title} · $price',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }),
            SizedBox(
              width: double.infinity,
              child: Obx(
                () => FilledButton.icon(
                  key: const ValueKey('premium_purchase_cta'),
                  onPressed: service.isLoading.value
                      ? null
                      : controller.purchase,
                  icon: service.isLoading.value
                      ? SizedBox(
                          width: 18.r,
                          height: 18.r,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: cs.onPrimary,
                          ),
                        )
                      : Icon(LucideIcons.heart, size: 18.r),
                  label: Text('premium_purchase'.tr),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OwnedPremiumView extends StatelessWidget {
  const _OwnedPremiumView({required this.cs});

  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72.r,
              height: 72.r,
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(24.r),
              ),
              child: Icon(LucideIcons.crown, color: cs.primary, size: 36.r),
            ),
            SizedBox(height: 18.h),
            Text(
              'premium_owned'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22.sp,
                fontWeight: FontWeight.w900,
                color: cs.onSurface,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'premium_ready'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                height: 1.4,
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
