import 'package:watch_your_money/domain/models/noir_settings_model.dart';

abstract class NoirSettingsRepository {
  Future<void> init();
  Future<NoirSettingsModel> getSettings();
  Future<void> saveSettings(NoirSettingsModel settings);
}