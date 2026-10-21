// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_action_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PendingActionModelAdapter extends TypeAdapter<PendingActionModel> {
  @override
  final int typeId = 13;

  @override
  PendingActionModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PendingActionModel(
      id: fields[0] as String,
      type: fields[1] as String,
      payload: (fields[2] as Map).cast<String, dynamic>(),
      status: fields[3] as String,
      createdAt: fields[4] as DateTime,
      confirmedAt: fields[5] as DateTime?,
      idempotencyKey: fields[6] as String,
      sessionId: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, PendingActionModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.payload)
      ..writeByte(3)
      ..write(obj.status)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.confirmedAt)
      ..writeByte(6)
      ..write(obj.idempotencyKey)
      ..writeByte(7)
      ..write(obj.sessionId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PendingActionModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
