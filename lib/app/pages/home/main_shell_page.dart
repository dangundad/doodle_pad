import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:doodle_pad/app/admob/ads_banner.dart';
import 'package:doodle_pad/app/admob/ads_helper.dart';
import 'package:doodle_pad/app/pages/gallery/gallery_page.dart';
import 'package:doodle_pad/app/pages/history/history_page.dart';
import 'package:doodle_pad/app/pages/home/home_page.dart';
import 'package:doodle_pad/app/pages/stats/stats_page.dart';
import 'package:doodle_pad/app/services/purchase_service.dart';

class MainShellPage extends StatefulWidget {
  const MainShellPage({super.key});

  @override
  State<MainShellPage> createState() => _MainShellPageState();
}

class _MainShellPageState extends State<MainShellPage> {
  int _selectedIndex = 0;

  static const List<Widget> _tabs = [
    HomeContentPage(),
    GalleryPage(),
    HistoryPage(),
    StatsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Get.theme.colorScheme;

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _tabs),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Obx(
            () => PurchaseService.isPremiumActive
                ? const SizedBox.shrink()
                : BannerAdWidget(
                    adUnitId: AdHelper.bannerAdUnitId,
                    type: AdHelper.banner,
                  ),
          ),
          Container(
            decoration: BoxDecoration(
              color: cs.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                child: GNav(
                  gap: 6,
                  iconSize: 22.r,
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 10.h,
                  ),
                  duration: const Duration(milliseconds: 300),
                  tabBackgroundColor: cs.primaryContainer,
                  color: cs.onSurfaceVariant,
                  activeColor: cs.primary,
                  tabs: [
                    GButton(icon: LucideIcons.house, text: 'nav_home'.tr),
                    GButton(icon: LucideIcons.image, text: 'nav_gallery'.tr),
                    GButton(icon: LucideIcons.history, text: 'nav_history'.tr),
                    GButton(
                      icon: LucideIcons.chartBarBig,
                      text: 'nav_stats'.tr,
                    ),
                  ],
                  selectedIndex: _selectedIndex,
                  onTabChange: (index) {
                    setState(() => _selectedIndex = index);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
