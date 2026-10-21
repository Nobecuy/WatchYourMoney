// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'noir_settings_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class NoirSettingsModelAdapter extends TypeAdapter<NoirSettingsModel> {
  @override
  final int typeId = 14;

  @override
  NoirSettingsModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NoirSettingsModel(
      modelName: fields[0] as String,
      ollamaHost: fields[1] as String,
      temperature: fields[2] as double,
      maxTokens: fields[3] as int,
      enabled: fields[4] as bool,
      maxToolCallsPerTurn: fields[5] as int,
      contextTokenBudget: fields[6] as int,
    );
  }

  @override
  void write(BinaryWriter writer, NoirSettingsModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.modelName)
      ..writeByte(1)
      ..write(obj.ollamaHost)
      ..writeByte(2)
      ..write(obj.temperature)
      ..writeByte(3)
      ..write(obj.maxTokens)
      ..writeByte(4)
      ..write(obj.enabled)
      ..writeByte(5)
      ..write(obj.maxToolCallsPerTurn)
      ..writeByte(6)
      ..write(obj.contextTokenBudget);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NoirSettingsModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
