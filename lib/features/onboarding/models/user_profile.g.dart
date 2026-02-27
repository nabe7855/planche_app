// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserProfileAdapter extends TypeAdapter<UserProfile> {
  @override
  final int typeId = 0;

  @override
  UserProfile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserProfile(
      name: fields[0] as String,
      weight: fields[1] as double?,
      targetGoal: fields[2] as String?,
      experienceLevel: fields[3] as String?,
      injuryHistory: (fields[4] as List).cast<String>(),
      currentPainAreas: (fields[5] as List).cast<String>(),
      lastUpdate: fields[6] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, UserProfile obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.weight)
      ..writeByte(2)
      ..write(obj.targetGoal)
      ..writeByte(3)
      ..write(obj.experienceLevel)
      ..writeByte(4)
      ..write(obj.injuryHistory)
      ..writeByte(5)
      ..write(obj.currentPainAreas)
      ..writeByte(6)
      ..write(obj.lastUpdate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfileAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
