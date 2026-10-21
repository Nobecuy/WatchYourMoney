import 'package:hive/hive.dart';
import 'package:watch_your_money/domain/models/noir_settings_model.dart';
import 'package:watch_your_money/domain/repositories/noir_settings_repository.dart';

class HiveNoirSettingsRepository implements NoirSettingsRepository {
  static const String _boxName = 'noir_settings';
  static const String _settingsKey = 'noir_settings';
  late Box<NoirSettingsModel> _box;

  @override
  Future<void> init() async {
    _box = await Hive.openBox<NoirSettingsModel>(_boxName);
  }

  @override
  Future<NoirSettingsModel> getSettings() async {
    return _box.get(_settingsKey) ?? NoirSettingsModel();
  }

  @override
  Future<void> saveSettings(NoirSettingsModel settings) async {
    await _box.put(_settingsKey, settings);
  }
}