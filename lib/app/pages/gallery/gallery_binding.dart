import 'package:get/get.dart';

import 'package:doodle_pad/app/controllers/gallery_controller.dart';

class GalleryBinding implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<GalleryController>(GalleryController.new);
  }
}
