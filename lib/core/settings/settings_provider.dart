import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:watch_your_money/core/settings/settings_model.dart';

const _kSettingsBox = 'settings';
const _kSettingsKey = 'app_settings';

// ── Notifier ────────────────────────────────────────────────────────────────

class SettingsNotifier extends StateNotifier<SettingsData> {
  SettingsNotifier() : super(SettingsData()) {
    _load();
  }

  Box<SettingsData> get _box => Hive.box<SettingsData>(_kSettingsBox);

  /// Load saved settings from Hive on first run.
  void _load() {
    final saved = _box.get(_kSettingsKey);
    if (saved != null) state = saved;
  }

  /// Persist state to Hive whenever it changes.
  Future<void> _save(SettingsData data) async {
    await _box.put(_kSettingsKey, data);
    state = data;
  }

  /// Change the display language. [code] must be 'en' or 'id'.
  Future<void> setLanguage(String code) async {
    await _save(state.copyWith(languageCode: code));
  }

  /// Change the display currency. [code] must be 'IDR', 'USD', 'EUR', or 'GBP'.
  Future<void> setCurrency(String code) async {
    await _save(state.copyWith(currencyCode: code));
  }

  /// Toggle Local Ollama AI. Persists to Hive.
  Future<void> setUseOllama(bool value) async {
    await _save(state.copyWith(useOllama: value));
  }

  /// Change the Ollama base URL. Persists to Hive.
  Future<void> setOllamaBaseUrl(String url) async {
    await _save(state.copyWith(ollamaBaseUrl: url));
  }
}

// ── Provider ────────────────────────────────────────────────────────────────

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsData>(
  (ref) => SettingsNotifier(),
);

// ── Helper: open the Hive box before runApp ─────────────────────────────────
// Call this in main() after Hive.initFlutter().

Future<void> openSettingsBox() async {
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(SettingsDataAdapter());
  }
  if (!Hive.isBoxOpen(_kSettingsBox)) {
    await Hive.openBox<SettingsData>(_kSettingsBox);
  }
}

// ── Derived providers (use these in screens for minimal rebuilds) ────────────

/// Provides only the currency code string — screens that only show money
/// amounts watch this to avoid rebuilding on language-only changes.
final currencyCodeProvider = Provider<String>(
  (ref) => ref.watch(settingsProvider).currencyCode,
);

/// Provides the full [SettingsData] — use when you need both language and
/// currency in the same widget (e.g. a screen header).
///
/// This is the same as watching [settingsProvider] directly; it exists as a
/// named alias to make intent explicit in screen code.
final appSettingsProvider = Provider<SettingsData>(
  (ref) => ref.watch(settingsProvider),
);
