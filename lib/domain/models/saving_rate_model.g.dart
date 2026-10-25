// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'saving_rate_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SavingRateAnalysisAdapter extends TypeAdapter<SavingRateAnalysis> {
  @override
  final int typeId = 7;

  @override
  SavingRateAnalysis read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SavingRateAnalysis(
      period: fields[0] as String,
      totalIncome: fields[1] as int,
      totalExpense: fields[2] as int,
      netSavings: fields[3] as int,
      savingRatePercent: fields[4] as double,
      category: fields[5] as SavingRateCategory,
      calculatedAt: fields[6] as DateTime,
      topExpenseCategories: (fields[7] as Map).cast<String, int>(),
      topIncomeCategories: (fields[8] as Map).cast<String, int>(),
    );
  }

  @override
  void write(BinaryWriter writer, SavingRateAnalysis obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.period)
      ..writeByte(1)
      ..write(obj.totalIncome)
      ..writeByte(2)
      ..write(obj.totalExpense)
      ..writeByte(3)
      ..write(obj.netSavings)
      ..writeByte(4)
      ..write(obj.savingRatePercent)
      ..writeByte(5)
      ..write(obj.category)
      ..writeByte(6)
      ..write(obj.calculatedAt)
      ..writeByte(7)
      ..write(obj.topExpenseCategories)
      ..writeByte(8)
      ..write(obj.topIncomeCategories);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SavingRateAnalysisAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SavingRateCategoryAdapter extends TypeAdapter<SavingRateCategory> {
  @override
  final int typeId = 8;

  @override
  SavingRateCategory read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SavingRateCategory.deficit;
      case 1:
        return SavingRateCategory.poor;
      case 2:
        return SavingRateCategory.standard;
      case 3:
        return SavingRateCategory.good;
      case 4:
        return SavingRateCategory.excellent;
      default:
        return SavingRateCategory.deficit;
    }
  }

  @override
  void write(BinaryWriter writer, SavingRateCategory obj) {
    switch (obj) {
      case SavingRateCategory.deficit:
        writer.writeByte(0);
        break;
      case SavingRateCategory.poor:
        writer.writeByte(1);
        break;
      case SavingRateCategory.standard:
        writer.writeByte(2);
        break;
      case SavingRateCategory.good:
        writer.writeByte(3);
        break;
      case SavingRateCategory.excellent:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SavingRateCategoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
