import 'package:hive/hive.dart';

part 'settings_model.g.dart';

/// Supported UI languages.
enum AppLanguage { english, indonesian }

/// Supported display currencies.
enum AppCurrency { idr, usd, eur, gbp }

// ── Hive Type Adapters ──────────────────────────────────────────────────────

@HiveType(typeId: 1)
class SettingsData extends HiveObject {
  @HiveField(0)
  String languageCode; // 'en' | 'id'

  @HiveField(1)
  String currencyCode; // 'IDR' | 'USD' | 'EUR' | 'GBP'

  @HiveField(2)
  bool useOllama; // default: false

  @HiveField(3)
  String ollamaBaseUrl; // default: 'http://10.0.2.2:11434'

  SettingsData({
    this.languageCode = 'en',
    this.currencyCode = 'IDR',
    this.useOllama = false,
    this.ollamaBaseUrl = 'http://10.0.2.2:11434',
  });

  // ── Convenience getters ──────────────────────────────────────────

  AppLanguage get language =>
      languageCode == 'id' ? AppLanguage.indonesian : AppLanguage.english;

  AppCurrency get currency {
    switch (currencyCode) {
      case 'USD':
        return AppCurrency.usd;
      case 'EUR':
        return AppCurrency.eur;
      case 'GBP':
        return AppCurrency.gbp;
      default:
        return AppCurrency.idr;
    }
  }

  // ── Currency display helpers ─────────────────────────────────────

  String get currencySymbol {
    switch (currencyCode) {
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      default:
        return 'Rp';
    }
  }

  String get currencyLabel {
    switch (currencyCode) {
      case 'USD':
        return 'USD (\$) — US Dollar';
      case 'EUR':
        return 'EUR (€) — Euro';
      case 'GBP':
        return 'GBP (£) — British Pound';
      default:
        return 'IDR (Rp) — Rupiah Indonesia';
    }
  }

  // ── Language display helpers ─────────────────────────────────────

  String get languageLabel =>
      languageCode == 'id' ? 'Bahasa Indonesia' : 'English (Default)';

  // ── copyWith ─────────────────────────────────────────────────────

  SettingsData copyWith({
    String? languageCode,
    String? currencyCode,
    bool? useOllama,
    String? ollamaBaseUrl,
  }) => SettingsData(
    languageCode: languageCode ?? this.languageCode,
    currencyCode: currencyCode ?? this.currencyCode,
    useOllama: useOllama ?? this.useOllama,
    ollamaBaseUrl: ollamaBaseUrl ?? this.ollamaBaseUrl,
  );
}
