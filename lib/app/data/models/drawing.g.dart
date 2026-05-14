// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'drawing.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SerializableStrokeAdapter extends TypeAdapter<SerializableStroke> {
  @override
  final typeId = 3;

  @override
  SerializableStroke read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SerializableStroke(
      colorArgb: (fields[0] as num).toInt(),
      width: (fields[1] as num).toDouble(),
      isEraser: fields[2] as bool,
      brushTypeIndex: (fields[3] as num).toInt(),
      seed: (fields[4] as num).toInt(),
      pointsXY: (fields[5] as List).cast<double>(),
    );
  }

  @override
  void write(BinaryWriter writer, SerializableStroke obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.colorArgb)
      ..writeByte(1)
      ..write(obj.width)
      ..writeByte(2)
      ..write(obj.isEraser)
      ..writeByte(3)
      ..write(obj.brushTypeIndex)
      ..writeByte(4)
      ..write(obj.seed)
      ..writeByte(5)
      ..write(obj.pointsXY);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SerializableStrokeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DrawingAdapter extends TypeAdapter<Drawing> {
  @override
  final typeId = 2;

  @override
  Drawing read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Drawing(
      id: fields[0] as String,
      createdAt: (fields[1] as num).toInt(),
      updatedAt: (fields[2] as num).toInt(),
      canvasColor: (fields[4] as num).toInt(),
      canvasLogicalWidth: (fields[5] as num).toDouble(),
      canvasLogicalHeight: (fields[6] as num).toDouble(),
      strokes: (fields[8] as List).cast<SerializableStroke>(),
      name: fields[3] as String?,
      referenceImagePath: fields[7] as String?,
      thumbnailPath: fields[9] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Drawing obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.createdAt)
      ..writeByte(2)
      ..write(obj.updatedAt)
      ..writeByte(3)
      ..write(obj.name)
      ..writeByte(4)
      ..write(obj.canvasColor)
      ..writeByte(5)
      ..write(obj.canvasLogicalWidth)
      ..writeByte(6)
      ..write(obj.canvasLogicalHeight)
      ..writeByte(7)
      ..write(obj.referenceImagePath)
      ..writeByte(8)
      ..write(obj.strokes)
      ..writeByte(9)
      ..write(obj.thumbnailPath);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DrawingAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
