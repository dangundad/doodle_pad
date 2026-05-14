import 'package:hive_ce/hive.dart';

part 'drawing.g.dart';

/// 영속화 가능한 단일 stroke 표현.
/// Design Ref: §3.1 — Offset adapter 대신 flatten double 리스트로 용량 절감.
@HiveType(typeId: 3)
class SerializableStroke {
  SerializableStroke({
    required this.colorArgb,
    required this.width,
    required this.isEraser,
    required this.brushTypeIndex,
    required this.seed,
    required this.pointsXY,
  });

  @HiveField(0)
  final int colorArgb;

  @HiveField(1)
  final double width;

  @HiveField(2)
  final bool isEraser;

  /// `BrushType.values` 인덱스. 미래 추가에 둔감하도록 enum 값 자체가 아니라 정수.
  @HiveField(3)
  final int brushTypeIndex;

  /// airbrush 등 spray pattern 안정성을 위한 시드.
  @HiveField(4)
  final int seed;

  /// `[x0, y0, x1, y1, ...]` 형태로 평탄화된 좌표 시퀀스.
  /// 짝수 길이가 보장되어야 한다.
  @HiveField(5)
  final List<double> pointsXY;
}

/// 사용자가 저장한 작품 1건.
/// Design Ref: §3.1 — canvasLogicalSize를 함께 보관해 재오픈 시 viewport 차이 흡수.
@HiveType(typeId: 2)
class Drawing extends HiveObject {
  Drawing({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.canvasColor,
    required this.canvasLogicalWidth,
    required this.canvasLogicalHeight,
    required this.strokes,
    this.name,
    this.referenceImagePath,
    this.thumbnailPath,
  });

  @HiveField(0)
  final String id;

  @HiveField(1)
  final int createdAt;

  @HiveField(2)
  int updatedAt;

  @HiveField(3)
  String? name;

  @HiveField(4)
  final int canvasColor;

  @HiveField(5)
  final double canvasLogicalWidth;

  @HiveField(6)
  final double canvasLogicalHeight;

  @HiveField(7)
  String? referenceImagePath;

  @HiveField(8)
  final List<SerializableStroke> strokes;

  /// ApplicationSupportDirectory 기준 절대 경로.
  /// 작품 삭제 시 같이 unlink된다 (Plan FR-12).
  @HiveField(9)
  String? thumbnailPath;
}
