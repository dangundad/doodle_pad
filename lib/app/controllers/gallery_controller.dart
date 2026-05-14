import 'package:get/get.dart';

import 'package:doodle_pad/app/data/models/drawing.dart';
import 'package:doodle_pad/app/services/artwork_repository.dart';

/// 작품 갤러리 페이지 전용 컨트롤러.
/// Design Ref: §2.1 — ArtworkRepository에 위임만 한다. Hive 직접 접근 금지.
class GalleryController extends GetxController {
  GalleryController({ArtworkRepository? repository})
    : _repository = repository ?? ArtworkRepository.instance;

  static GalleryController get to => Get.find<GalleryController>();

  /// Plan FR-09 — 100개 초과 시 경고 배너를 그리기 위한 임계값.
  static const int warnAboveCount = 100;

  final ArtworkRepository _repository;

  final RxList<Drawing> artworks = <Drawing>[].obs;
  final RxBool isLoading = false.obs;

  bool get isAboveWarnThreshold => artworks.length > warnAboveCount;

  @override
  void onInit() {
    super.onInit();
    refreshList();
  }

  void refreshList() {
    isLoading.value = true;
    try {
      artworks.assignAll(_repository.listAll());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteArtwork(String id) async {
    await _repository.delete(id);
    refreshList();
  }

  Drawing? findById(String id) => _repository.findById(id);
}
