// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_message_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ChatMessageModelAdapter extends TypeAdapter<ChatMessageModel> {
  @override
  final int typeId = 10;

  @override
  ChatMessageModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ChatMessageModel(
      id: fields[0] as String,
      role: fields[1] as String,
      content: fields[2] as String,
      toolCalls: (fields[3] as List?)?.cast<ToolCall>(),
      toolResults: (fields[4] as List?)?.cast<ToolResult>(),
      timestamp: fields[5] as DateTime,
      sessionId: fields[6] as String,
    );
  }

  @override
  void write(BinaryWriter writer, ChatMessageModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.role)
      ..writeByte(2)
      ..write(obj.content)
      ..writeByte(3)
      ..write(obj.toolCalls)
      ..writeByte(4)
      ..write(obj.toolResults)
      ..writeByte(5)
      ..write(obj.timestamp)
      ..writeByte(6)
      ..write(obj.sessionId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatMessageModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ToolCallAdapter extends TypeAdapter<ToolCall> {
  @override
  final int typeId = 11;

  @override
  ToolCall read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ToolCall(
      id: fields[0] as String,
      name: fields[1] as String,
      arguments: (fields[2] as Map).cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, ToolCall obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.arguments);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ToolCallAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ToolResultAdapter extends TypeAdapter<ToolResult> {
  @override
  final int typeId = 12;

  @override
  ToolResult read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ToolResult(
      toolCallId: fields[0] as String,
      name: fields[1] as String,
      content: fields[2] as String,
      isError: fields[3] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, ToolResult obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.toolCallId)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.content)
      ..writeByte(3)
      ..write(obj.isError);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ToolResultAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
