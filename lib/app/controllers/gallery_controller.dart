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

  /// Design Ref: §5.3 — 다중 선택 삭제 모드.
  final RxBool deleteMode = false.obs;
  final RxSet<String> selectedIds = <String>{}.obs;

  bool get isAboveWarnThreshold => artworks.length > warnAboveCount;
  bool get hasSelection => selectedIds.isNotEmpty;

  @override
  void onInit() {
    super.onInit();
    refreshList();
  }

  void refreshList() {
    isLoading.value = true;
    try {
      artworks.assignAll(_repository.listAll());
      // 목록이 갱신되면 사라진 작품의 선택 상태를 정리한다.
      final liveIds = artworks.map((a) => a.id).toSet();
      selectedIds.removeWhere((id) => !liveIds.contains(id));
    } finally {
      isLoading.value = false;
    }
  }

  // ---- 삭제 모드 ----

  void toggleDeleteMode() {
    if (deleteMode.value) {
      exitDeleteMode();
    } else {
      deleteMode.value = true;
    }
  }

  void exitDeleteMode() {
    deleteMode.value = false;
    selectedIds.clear();
  }

  void toggleSelect(String id) {
    if (selectedIds.contains(id)) {
      selectedIds.remove(id);
    } else {
      selectedIds.add(id);
    }
  }

  bool isSelected(String id) => selectedIds.contains(id);

  /// 선택된 작품을 일괄 삭제한다. 각 작품의 썸네일 파일도 함께 제거된다(FR-12).
  Future<void> deleteSelected() async {
    final ids = selectedIds.toList();
    for (final id in ids) {
      await _repository.delete(id);
    }
    exitDeleteMode();
    refreshList();
  }

  /// 선택된 작품 중 썸네일 파일이 존재하는 것들의 경로 목록 (공유용).
  List<String> selectedThumbnailPaths() {
    return artworks
        .where((a) => selectedIds.contains(a.id) && a.thumbnailPath != null)
        .map((a) => a.thumbnailPath!)
        .toList();
  }

  Future<void> deleteArtwork(String id) async {
    await _repository.delete(id);
    refreshList();
  }

  Drawing? findById(String id) => _repository.findById(id);
}
