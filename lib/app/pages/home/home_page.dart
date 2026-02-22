// ================================================
// DangunDad Flutter App - home_page.dart Template
// ================================================
// doodle_pad 치환 후 사용

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:doodle_pad/app/controllers/home_controller.dart';

class HomePage extends GetView<HomeController> {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('app_name'.tr)),
      body: Center(
        child: Text('Hello, World!', style: TextStyle(fontSize: 24.sp)),
      ),
    );
  }
}
