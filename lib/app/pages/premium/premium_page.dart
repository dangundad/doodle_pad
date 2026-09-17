import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:doodle_pad/app/controllers/premium_controller.dart';
import 'package:doodle_pad/app/services/purchase_service.dart';
import 'package:doodle_pad/app/theme/app_theme.dart';
import 'package:doodle_pad/app/widgets/app_ui.dart';

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
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: Text('premium_title'.tr),
        actions: [
          Obx(
            () => IconButton(
              tooltip: 'premium_restore'.tr,
              onPressed: service.isLoading.value ? null : controller.restore,
              icon: const Icon(LucideIcons.rotateCcw),
            ),
          ),
          SizedBox(width: 4.w),
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
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
      children: [
        _HeroPanel(cs: cs),
        SizedBox(height: 22.h),
        SectionLabel('premium_plan_title'.tr),
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
        SizedBox(height: 4.h),
        Text(
          'premium_purchase_note'.tr,
          style: TextStyle(
            color: cs.onSurfaceVariant,
            fontSize: 13.sp,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

/// 히어로 — 제목/설명 + 혜택 3줄을 한 패널에 담는다.
class _HeroPanel extends StatelessWidget {
  const _HeroPanel({required this.cs});

  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final benefits = [
      (LucideIcons.badgeCheck, 'premium_benefit_remove_ads'.tr),
      (LucideIcons.paintbrush, 'premium_benefit_premium_brushes'.tr),
      (LucideIcons.heart, 'premium_benefit_one_time_support'.tr),
    ];

    return AppPanel(
      color: cs.surfaceContainerLow,
      radius: AppTheme.radiusLg,
      padding: EdgeInsets.all(18.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const IconBadge(
            LucideIcons.crown,
            size: 48,
            tone: IconBadgeTone.accent,
          ),
          SizedBox(height: 14.h),
          Text(
            'premium_support_title'.tr,
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
              height: 1.15,
              color: cs.onSurface,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'premium_subtitle'.tr,
            style: TextStyle(
              fontSize: 14.sp,
              height: 1.4,
              color: cs.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 16.h),
          Divider(height: 1, color: cs.outlineVariant),
          SizedBox(height: 12.h),
          for (var i = 0; i < benefits.length; i++)
            Padding(
              padding: EdgeInsets.only(
                bottom: i < benefits.length - 1 ? 10.h : 0,
              ),
              child: Row(
                children: [
                  Icon(benefits[i].$1, color: cs.tertiary, size: 18.r),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      benefits[i].$2,
                      style: TextStyle(
                        fontSize: 14.sp,
                        height: 1.3,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
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

/// 후원 옵션 — 라디오 느낌의 선택 카드. 선택 시 잉크색 테두리 + 체크.
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
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppTheme.radiusMd.r),
      side: BorderSide(
        color: selected ? cs.primary : cs.outlineVariant,
        width: selected ? 2 : 1,
      ),
    );

    return Material(
      color: cs.surfaceContainerLowest,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? onTap : null,
        customBorder: shape,
        child: Padding(
          padding: EdgeInsets.all(14.w),
          child: Row(
            children: [
              IconBadge(
                icon,
                size: 44,
                tone: selected ? IconBadgeTone.primary : IconBadgeTone.neutral,
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
                              fontWeight: FontWeight.w700,
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
                            color: cs.onSurface,
                            fontWeight: FontWeight.w800,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      plan.description,
                      style: TextStyle(
                        fontSize: 13.sp,
                        height: 1.3,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    if (badge != null) ...[
                      SizedBox(height: 8.h),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 3.h,
                        ),
                        decoration: BoxDecoration(
                          color: cs.secondaryContainer,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(
                            color: cs.onSecondaryContainer,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w800,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(width: 10.w),
              _RadioMark(selected: selected, cs: cs),
            ],
          ),
        ),
      ),
    );
  }
}

class _RadioMark extends StatelessWidget {
  const _RadioMark({required this.selected, required this.cs});

  final bool selected;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 22.r,
      height: 22.r,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? cs.primary : Colors.transparent,
        border: Border.all(
          color: selected ? cs.primary : cs.outline,
          width: 1.5,
        ),
      ),
      child: selected
          ? Icon(LucideIcons.check, size: 14.r, color: cs.onPrimary)
          : null,
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
        padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 14.h),
        decoration: BoxDecoration(
          color: cs.surface,
          border: Border(top: BorderSide(color: cs.outlineVariant)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Obx(() {
              final plan = controller.plans[controller.selectedPlanIndex.value];
              final price = controller.planPrice(
                controller.selectedPlanIndex.value,
              );

              return Padding(
                padding: EdgeInsets.only(bottom: 10.h),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        plan.title,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      price,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            }),
            SizedBox(
              width: double.infinity,
              height: 52.h,
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
            const IconBadge(
              LucideIcons.crown,
              size: 72,
              tone: IconBadgeTone.accent,
            ),
            SizedBox(height: 18.h),
            Text(
              'premium_owned'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22.sp,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
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
