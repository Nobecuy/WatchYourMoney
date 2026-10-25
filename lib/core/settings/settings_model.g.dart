// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SettingsDataAdapter extends TypeAdapter<SettingsData> {
  @override
  final int typeId = 1;

  @override
  SettingsData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SettingsData(
      languageCode: fields[0] as String,
      currencyCode: fields[1] as String,
      useOllama: fields[2] as bool,
      ollamaBaseUrl: fields[3] as String,
    );
  }

  @override
  void write(BinaryWriter writer, SettingsData obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.languageCode)
      ..writeByte(1)
      ..write(obj.currencyCode)
      ..writeByte(2)
      ..write(obj.useOllama)
      ..writeByte(3)
      ..write(obj.ollamaBaseUrl);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SettingsDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
