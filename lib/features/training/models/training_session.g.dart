// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'training_session.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TrainingSessionAdapter extends TypeAdapter<TrainingSession> {
  @override
  final int typeId = 1;

  @override
  TrainingSession read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TrainingSession(
      date: fields[0] as DateTime,
      bestHoldMs: fields[1] as int,
      totalHoldMs: fields[2] as int,
      holdCount: fields[3] as int,
      planName: fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, TrainingSession obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.bestHoldMs)
      ..writeByte(2)
      ..write(obj.totalHoldMs)
      ..writeByte(3)
      ..write(obj.holdCount)
      ..writeByte(4)
      ..write(obj.planName);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrainingSessionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
