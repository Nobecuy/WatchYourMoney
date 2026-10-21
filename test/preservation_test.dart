/// Preservation Property Tests
///
/// **Property 5: Preservation — Non-Buggy Inputs Unchanged**
///
/// These tests observe and encode the existing, correct behavior of the app
/// for inputs where NONE of the four bug conditions apply. They MUST PASS on
/// unfixed code and MUST CONTINUE TO PASS after all fixes are applied.
///
/// Test areas:
/// 1. CurrencyFormatter.formatStatic (legacy IDR) — Rp symbol always present
/// 2. SettingsData field 0 & 1 backward compatibility
/// 3. AppTranslations keys non-empty for both 'en' and 'id'
// ignore_for_file: always_use_package_imports
library;

/// 4. SettingsData useOllama and ollamaBaseUrl defaults and copyWith
/// 5. SettingsData pure model behavior (copyWith for language and currency)
/// 6. TopicGate non-finance query rejection
///
/// **EXPECTED OUTCOME**: All tests PASS on unfixed and fixed code.
///
/// **Validates: Requirements 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7, 3.8, 3.10**

import 'package:flutter_test/flutter_test.dart';
import 'package:watch_your_money/core/i18n/app_translations.dart';
import 'package:watch_your_money/core/settings/settings_model.dart';
import 'package:watch_your_money/core/utils/currency_formatter.dart';
import 'package:watch_your_money/core/ai/topic_gate.dart';

void main() {
  // ─────────────────────────────────────────────────────────────────────────
  // Test 1 — CurrencyFormatter.formatStatic (legacy IDR)
  //
  // Preservation: formatStatic() and compactStatic() remain available as the
  // IDR-only legacy API and always return a string containing 'Rp'.
  // **Validates: Requirements 3.3**
  // ─────────────────────────────────────────────────────────────────────────
  group('Test 1 — CurrencyFormatter.formatStatic legacy IDR', () {
    const amounts = [0.0, 100.0, 1000.0, 150000.0, 1500000.0, 1000000000.0];

    for (final amount in amounts) {
      test('formatStatic($amount) contains Rp', () {
        final result = CurrencyFormatter.formatStatic(amount);
        expect(
          result,
          contains('Rp'),
          reason: 'formatStatic($amount) must contain "Rp" — got: "$result"',
        );
      });
    }

    test('compactStatic(150000) contains Rp', () {
      final result = CurrencyFormatter.compactStatic(150000);
      expect(
        result,
        contains('Rp'),
        reason: 'compactStatic must return an Rp-formatted string',
      );
    });

    test('compactStatic(1500000) contains Rp and jt abbreviation', () {
      final result = CurrencyFormatter.compactStatic(1500000);
      expect(
        result,
        contains('Rp'),
        reason: 'compactStatic for millions must contain Rp',
      );
      expect(
        result,
        contains('jt'),
        reason: 'compactStatic for >= 1M must use "jt" abbreviation',
      );
    });

    test('compactStatic(500000) contains Rp and rb abbreviation', () {
      final result = CurrencyFormatter.compactStatic(500000);
      expect(
        result,
        contains('Rp'),
        reason: 'compactStatic for thousands must contain Rp',
      );
      expect(
        result,
        contains('rb'),
        reason: 'compactStatic for >= 1K must use "rb" abbreviation',
      );
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Test 2 — SettingsData field 0 & 1 backward compatibility
  //
  // Preservation: HiveField(0) languageCode and HiveField(1) currencyCode
  // must remain accessible and correct after new fields are added.
  // **Validates: Requirements 3.5**
  // ─────────────────────────────────────────────────────────────────────────
  group('Test 2 — SettingsData field 0 & 1 backward compatibility', () {
    test('languageCode defaults to "en"', () {
      final settings = SettingsData();
      expect(
        settings.languageCode,
        equals('en'),
        reason: 'Default languageCode (HiveField 0) must be "en"',
      );
    });

    test('currencyCode defaults to "IDR"', () {
      final settings = SettingsData();
      expect(
        settings.currencyCode,
        equals('IDR'),
        reason: 'Default currencyCode (HiveField 1) must be "IDR"',
      );
    });

    test('SettingsData(languageCode: "id", currencyCode: "USD") preserves both fields', () {
      final settings = SettingsData(languageCode: 'id', currencyCode: 'USD');
      expect(
        settings.languageCode,
        equals('id'),
        reason: 'languageCode (HiveField 0) must be "id" as specified',
      );
      expect(
        settings.currencyCode,
        equals('USD'),
        reason: 'currencyCode (HiveField 1) must be "USD" as specified',
      );
    });

    test('copyWith preserves field 0 and 1 when not overridden', () {
      final original = SettingsData(languageCode: 'id', currencyCode: 'EUR');
      final copy = original.copyWith();
      expect(
        copy.languageCode,
        equals('id'),
        reason: 'copyWith() with no args must preserve languageCode',
      );
      expect(
        copy.currencyCode,
        equals('EUR'),
        reason: 'copyWith() with no args must preserve currencyCode',
      );
    });

    test('copyWith can update languageCode', () {
      final settings = SettingsData(languageCode: 'en');
      final updated = settings.copyWith(languageCode: 'id');
      expect(
        updated.languageCode,
        equals('id'),
        reason: 'copyWith(languageCode: "id") must update the field',
      );
    });

    test('copyWith can update currencyCode', () {
      final settings = SettingsData(currencyCode: 'IDR');
      final updated = settings.copyWith(currencyCode: 'GBP');
      expect(
        updated.currencyCode,
        equals('GBP'),
        reason: 'copyWith(currencyCode: "GBP") must update the field',
      );
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Test 3 — AppTranslations keys non-empty
  //
  // Preservation: All translation keys used across screens must return
  // non-empty strings for both 'en' and 'id' language codes.
  // **Validates: Requirements 3.1, 3.2**
  // ─────────────────────────────────────────────────────────────────────────
  group('Test 3 — AppTranslations keys non-empty', () {
    for (final langCode in ['en', 'id']) {
      group('language: $langCode', () {
        late AppTranslations t;
        setUp(() => t = AppTranslations.of(langCode));

        test('recentTx is non-empty', () {
          expect(
            t.recentTx,
            isNotEmpty,
            reason: 'AppTranslations($langCode).recentTx must not be empty',
          );
        });

        test('netWorth is non-empty', () {
          expect(
            t.netWorth,
            isNotEmpty,
            reason: 'AppTranslations($langCode).netWorth must not be empty',
          );
        });

        test('cashFlow7d is non-empty', () {
          expect(
            t.cashFlow7d,
            isNotEmpty,
            reason: 'AppTranslations($langCode).cashFlow7d must not be empty',
          );
        });

        test('noTransactions is non-empty', () {
          expect(
            t.noTransactions,
            isNotEmpty,
            reason:
                'AppTranslations($langCode).noTransactions must not be empty',
          );
        });

        test('allLabel is non-empty', () {
          expect(
            t.allLabel,
            isNotEmpty,
            reason: 'AppTranslations($langCode).allLabel must not be empty',
          );
        });

        test('income is non-empty', () {
          expect(
            t.income,
            isNotEmpty,
            reason: 'AppTranslations($langCode).income must not be empty',
          );
        });

        test('expense is non-empty', () {
          expect(
            t.expense,
            isNotEmpty,
            reason: 'AppTranslations($langCode).expense must not be empty',
          );
        });

        test('walletHistory is non-empty', () {
          expect(
            t.walletHistory,
            isNotEmpty,
            reason:
                'AppTranslations($langCode).walletHistory must not be empty',
          );
        });

        test('activeWallet is non-empty', () {
          expect(
            t.activeWallet,
            isNotEmpty,
            reason: 'AppTranslations($langCode).activeWallet must not be empty',
          );
        });

        test('totalBalance is non-empty', () {
          expect(
            t.totalBalance,
            isNotEmpty,
            reason: 'AppTranslations($langCode).totalBalance must not be empty',
          );
        });
      });
    }

    test('English and Indonesian translations are distinct for recentTx', () {
      final en = AppTranslations.of('en');
      final id = AppTranslations.of('id');
      expect(
        en.recentTx,
        isNot(equals(id.recentTx)),
        reason: 'English and Indonesian recentTx translations must differ',
      );
    });

    test('English and Indonesian translations are distinct for netWorth', () {
      final en = AppTranslations.of('en');
      final id = AppTranslations.of('id');
      expect(
        en.netWorth,
        isNot(equals(id.netWorth)),
        reason: 'English and Indonesian netWorth translations must differ',
      );
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Test 4 — SettingsData useOllama and ollamaBaseUrl fields
  //
  // These fields are confirmed present (from task 1 results). Verify defaults
  // and copyWith behavior are correct as preservation baseline.
  // **Validates: Requirements 3.5, 3.6**
  // ─────────────────────────────────────────────────────────────────────────
  group('Test 4 — SettingsData useOllama and ollamaBaseUrl', () {
    test('default useOllama is false', () {
      final settings = SettingsData();
      expect(
        settings.useOllama,
        isFalse,
        reason: 'Default useOllama must be false',
      );
    });

    test('default ollamaBaseUrl is the Android emulator address', () {
      final settings = SettingsData();
      expect(
        settings.ollamaBaseUrl,
        equals('http://10.0.2.2:11434'),
        reason: 'Default ollamaBaseUrl must be "http://10.0.2.2:11434"',
      );
    });

    test('copyWith(useOllama: true) updates the field', () {
      final settings = SettingsData(useOllama: false);
      final updated = settings.copyWith(useOllama: true);
      expect(
        updated.useOllama,
        isTrue,
        reason: 'copyWith(useOllama: true) must update the field',
      );
    });

    test('copyWith preserves useOllama when not specified', () {
      final original = SettingsData(
        useOllama: true,
        ollamaBaseUrl: 'http://192.168.1.5:11434',
      );
      final copy = original.copyWith(currencyCode: 'USD');
      expect(
        copy.useOllama,
        isTrue,
        reason:
            'copyWith must preserve useOllama when not explicitly overridden',
      );
      expect(
        copy.ollamaBaseUrl,
        equals('http://192.168.1.5:11434'),
        reason: 'copyWith must preserve ollamaBaseUrl when not explicitly overridden',
      );
    });

    test('copyWith(ollamaBaseUrl: ...) updates the URL', () {
      final settings = SettingsData();
      final updated = settings.copyWith(
        ollamaBaseUrl: 'http://localhost:11434',
      );
      expect(
        updated.ollamaBaseUrl,
        equals('http://localhost:11434'),
        reason: 'copyWith must update ollamaBaseUrl when specified',
      );
    });

    test('adding new fields does not corrupt existing field 0 and 1', () {
      final settings = SettingsData(
        languageCode: 'id',
        currencyCode: 'EUR',
        useOllama: true,
        ollamaBaseUrl: 'http://192.168.0.1:11434',
      );
      expect(
        settings.languageCode,
        equals('id'),
        reason: 'HiveField(0) languageCode must remain accessible',
      );
      expect(
        settings.currencyCode,
        equals('EUR'),
        reason: 'HiveField(1) currencyCode must remain accessible',
      );
      expect(
        settings.useOllama,
        isTrue,
        reason: 'HiveField(2) useOllama must be accessible',
      );
      expect(
        settings.ollamaBaseUrl,
        equals('http://192.168.0.1:11434'),
        reason: 'HiveField(3) ollamaBaseUrl must be accessible',
      );
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Test 5 — SettingsData pure model: setLanguage/setCurrency via copyWith
  //
  // Since Hive is not initialized in unit tests, we validate the underlying
  // pure data model behavior that SettingsNotifier.setLanguage/setCurrency
  // delegates to via copyWith.
  // **Validates: Requirements 3.4, 3.6**
  // ─────────────────────────────────────────────────────────────────────────
  group('Test 5 — SettingsData pure model persistence behavior', () {
    test('setLanguage behavior: copyWith produces correct state', () {
      // Simulates what SettingsNotifier.setLanguage("id") does internally
      final initial = SettingsData();
      final afterSet = initial.copyWith(languageCode: 'id');
      expect(
        afterSet.languageCode,
        equals('id'),
        reason:
            'setLanguage("id") via copyWith must produce languageCode = "id"',
      );
      expect(
        afterSet.currencyCode,
        equals('IDR'),
        reason: 'setLanguage must not alter currencyCode',
      );
    });

    test('setCurrency behavior: copyWith produces correct state', () {
      // Simulates what SettingsNotifier.setCurrency("EUR") does internally
      final initial = SettingsData();
      final afterSet = initial.copyWith(currencyCode: 'EUR');
      expect(
        afterSet.currencyCode,
        equals('EUR'),
        reason:
            'setCurrency("EUR") via copyWith must produce currencyCode = "EUR"',
      );
      expect(
        afterSet.languageCode,
        equals('en'),
        reason: 'setCurrency must not alter languageCode',
      );
    });

    test('chained copyWith for language then currency preserves both', () {
      final step1 = SettingsData().copyWith(languageCode: 'id');
      final step2 = step1.copyWith(currencyCode: 'USD');
      expect(
        step2.languageCode,
        equals('id'),
        reason:
            'chained copyWith must preserve languageCode after currency update',
      );
      expect(
        step2.currencyCode,
        equals('USD'),
        reason:
            'chained copyWith must preserve currencyCode after language update',
      );
    });

    test('all four supported currency codes are accepted', () {
      for (final code in ['IDR', 'USD', 'EUR', 'GBP']) {
        final settings = SettingsData(currencyCode: code);
        expect(
          settings.currencyCode,
          equals(code),
          reason: 'currency code "$code" must be stored as-is',
        );
      }
    });

    test('both supported language codes are accepted', () {
      for (final code in ['en', 'id']) {
        final settings = SettingsData(languageCode: code);
        expect(
          settings.languageCode,
          equals(code),
          reason: 'language code "$code" must be stored as-is',
        );
      }
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Test 6 — TopicGate non-finance query rejection
  //
  // Preservation: TopicGate.classify() must continue to reject non-finance
  // queries regardless of any AI routing changes applied in other tasks.
  // **Validates: Requirements 3.8**
  // ─────────────────────────────────────────────────────────────────────────
  group('Test 6 — TopicGate non-finance query rejection', () {
    const nonFinanceQueries = [
      'siapa presiden Indonesia?',
      'resep masak ayam goreng',
      'bagaimana cara belajar coding?',
      'cerita dongeng kancil',
      'siapa artis terpopuler tahun ini?',
      'tolong buatkan tutorial html',
      'sejarah perang dunia kedua',
      'kimia dasar untuk SMA',
      'siapa yang main di film itu?',
      'bagaimana cara membuat website?',
    ];

    for (final query in nonFinanceQueries) {
      test('rejects: "$query"', () {
        final result = TopicGate.classify(query);
        expect(
          result.$1,
          isFalse,
          reason: 'TopicGate must reject non-finance query: "$query"',
        );
      });
    }

    test('TopicGate allows finance queries (positive preservation)', () {
      const financeQueries = [
        'berapa total pengeluaran bulan ini?',
        'tunjukkan ringkasan saldo saya',
        'analisis pengeluaran terbesar saya',
        'berapa pemasukan saya minggu ini?',
      ];
      for (final query in financeQueries) {
        final result = TopicGate.classify(query);
        expect(
          result.$1,
          isTrue,
          reason: 'TopicGate must allow finance query: "$query"',
        );
      }
    });

    test('getRejectionMessage returns non-empty string', () {
      final msg = TopicGate.getRejectionMessage();
      expect(
        msg,
        isNotEmpty,
        reason: 'getRejectionMessage must return a non-empty rejection string',
      );
    });
  });
}
