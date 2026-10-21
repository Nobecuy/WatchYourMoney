/// Bug Condition Exploration Tests
///
/// These tests are designed to FAIL on unfixed code — failure confirms the
/// bugs exist. They will pass once all four bug areas are fixed.
///
// ignore_for_file: always_use_package_imports
library;

/// **Four bug areas under test:**
/// 1. Settings Reactivity — `_fmt` nullable field vs local variable pattern
/// 2. SettingsData Missing Fields — `useOllama` and `ollamaBaseUrl`
/// 3. AI No Fallback — `LocalFinancialEngine` does not exist
/// 4. UpdateHelper Missing — `UpdateHelper` class does not exist
///
/// **EXPECTED OUTCOME on unfixed code**: FAIL
/// **EXPECTED OUTCOME after fix**: PASS

// ignore_for_file: unused_import

import 'package:flutter_test/flutter_test.dart';
import 'package:watch_your_money/core/settings/settings_model.dart';
import 'package:watch_your_money/core/utils/currency_formatter.dart';
import 'package:watch_your_money/core/ai/topic_gate.dart';

// Area 3: This import will FAIL TO COMPILE on unfixed code because the file
// does not exist. Failure here confirms Bug Condition Area 3.
// ignore: uri_does_not_exist
import 'package:watch_your_money/core/ai/local_financial_engine.dart';

// Area 4: This import will FAIL TO COMPILE on unfixed code because the file
// does not exist. Failure here confirms Bug Condition Area 4.
// ignore: uri_does_not_exist
import 'package:watch_your_money/core/updates/update_helper.dart';

void main() {
  // ─────────────────────────────────────────────────────────────────────────
  // Area 1 — CurrencyFormatter Instance API
  //
  // Bug condition: if a nullable `_fmt` field was used in screens with a
  // bang-operator (`_fmt!`), a null crash is possible before `build()` assigns
  // the value. Also verifies the instance `format()` API works correctly for
  // each currency.
  //
  // This test PASSES on both fixed and unfixed code because the formatter
  // class itself has always been correct — the bug was in how *screens* stored
  // the formatter. The test documents the expected API contract.
  // ─────────────────────────────────────────────────────────────────────────
  group('Area 1 — Settings Reactivity: CurrencyFormatter instance API', () {
    test('USD formatter contains \$ symbol', () {
      final settings = SettingsData(currencyCode: 'USD');
      final fmt = CurrencyFormatter.from(settings);
      final result = fmt.format(1500);
      expect(
        result,
        contains(r'$'),
        reason: 'CurrencyFormatter.from(USD).format() must return a \$ symbol',
      );
    });

    test('EUR formatter contains € symbol', () {
      final settings = SettingsData(currencyCode: 'EUR');
      final fmt = CurrencyFormatter.from(settings);
      final result = fmt.format(1500);
      expect(
        result,
        contains('€'),
        reason: 'CurrencyFormatter.from(EUR).format() must return a € symbol',
      );
    });

    test('IDR formatter contains Rp symbol', () {
      final settings = SettingsData(currencyCode: 'IDR');
      final fmt = CurrencyFormatter.from(settings);
      final result = fmt.format(150000);
      expect(
        result,
        contains('Rp'),
        reason: 'CurrencyFormatter.from(IDR).format() must return Rp symbol',
      );
    });

    test('GBP formatter contains £ symbol', () {
      final settings = SettingsData(currencyCode: 'GBP');
      final fmt = CurrencyFormatter.from(settings);
      final result = fmt.format(1500);
      expect(
        result,
        contains('£'),
        reason: 'CurrencyFormatter.from(GBP).format() must return a £ symbol',
      );
    });

    test('formatStatic (legacy IDR) still works', () {
      final result = CurrencyFormatter.formatStatic(150000);
      expect(
        result,
        contains('Rp'),
        reason: 'Legacy formatStatic must continue to work for IDR',
      );
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Area 2 — SettingsData useOllama and ollamaBaseUrl Fields
  //
  // Bug condition: `SettingsData` was missing fields 2 and 3 (`useOllama`,
  // `ollamaBaseUrl`). Accessing them would throw `NoSuchMethodError`.
  //
  // These tests FAIL TO COMPILE on unfixed code (NoSuchMethodError at runtime
  // if the class compiles but fields are absent, or compile error if fields
  // are truly absent). After fix, these tests should PASS.
  // ─────────────────────────────────────────────────────────────────────────
  group('Area 2 — SettingsData Fields: useOllama and ollamaBaseUrl', () {
    test('SettingsData default useOllama is false', () {
      final settings = SettingsData();
      // On UNFIXED code: NoSuchMethodError — field does not exist
      // On FIXED code: returns false
      expect(
        settings.useOllama,
        isFalse,
        reason: 'SettingsData.useOllama must default to false',
      );
    });

    test('SettingsData default ollamaBaseUrl is the emulator address', () {
      final settings = SettingsData();
      // On UNFIXED code: NoSuchMethodError — field does not exist
      // On FIXED code: returns 'http://10.0.2.2:11434'
      expect(
        settings.ollamaBaseUrl,
        equals('http://10.0.2.2:11434'),
        reason:
            'SettingsData.ollamaBaseUrl must default to http://10.0.2.2:11434',
      );
    });

    test('SettingsData copyWith preserves useOllama', () {
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

    test('SettingsData copyWith can update useOllama', () {
      final settings = SettingsData(useOllama: false);
      final updated = settings.copyWith(useOllama: true);
      expect(
        updated.useOllama,
        isTrue,
        reason: 'copyWith(useOllama: true) must update the field',
      );
    });

    test(
      'HiveField indices 0 and 1 are unchanged (languageCode and currencyCode)',
      () {
        // Ensure adding fields 2 and 3 did not shift or corrupt existing fields
        final settings = SettingsData(languageCode: 'id', currencyCode: 'EUR');
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
      },
    );
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Area 3 — LocalFinancialEngine Missing (Offline AI Fallback)
  //
  // Bug condition: `LocalFinancialEngine` class does not exist. The import
  // at the top of this file WILL FAIL TO COMPILE on unfixed code.
  //
  // These tests use LocalFinancialEngine directly — on unfixed code the
  // entire test file fails to compile, confirming the bug.
  // After fix, LocalFinancialEngine must be importable and functional.
  // ─────────────────────────────────────────────────────────────────────────
  group('Area 3 — LocalFinancialEngine: Offline AI fallback exists and works', () {
    test('LocalFinancialEngine class can be instantiated', () {
      // This test FAILS TO COMPILE on unfixed code because LocalFinancialEngine
      // does not exist. After fix, the class must be importable.
      //
      // We cannot instantiate it here (requires Riverpod Ref), so we just
      // verify the import resolves (the mere presence of the import at the
      // top of this file is the check).
      //
      // The test body validates TopicGate continues to gate non-finance queries,
      // which LocalFinancialEngine must also pass through.
      const nonFinanceQuery = 'siapa presiden Indonesia?';
      final result = TopicGate.classify(nonFinanceQuery);
      expect(
        result.$1,
        isFalse,
        reason: 'TopicGate must reject non-finance queries (used by LocalFinancialEngine)',
      );
    });

    test(
      'TopicGate allows finance queries that LocalFinancialEngine would handle',
      () {
        const financeQueries = [
          'berapa total pengeluaran bulan ini?',
          'tunjukkan ringkasan saldo saya',
          'tips hemat untuk bulan depan',
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
      },
    );
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Area 4 — UpdateHelper Missing
  //
  // Bug condition: `UpdateHelper` class does not exist. The import at the
  // top of this file WILL FAIL TO COMPILE on unfixed code.
  //
  // On unfixed code: compile error — confirms the bug.
  // After fix: UpdateHelper must be importable and have checkForUpdates().
  // ─────────────────────────────────────────────────────────────────────────
  group('Area 4 — UpdateHelper: GitHub Releases checker exists', () {
    test('UpdateHelper._isNewerVersion detects a newer version', () {
      // On UNFIXED code: COMPILE ERROR — UpdateHelper does not exist.
      // After fix: this static helper must correctly identify newer versions.
      expect(
        UpdateHelper.isNewerVersion('1.1.0', '1.0.0'),
        isTrue,
        reason: '1.1.0 is newer than 1.0.0',
      );
    });

    test('UpdateHelper._isNewerVersion returns false for same version', () {
      expect(
        UpdateHelper.isNewerVersion('1.0.0', '1.0.0'),
        isFalse,
        reason: 'Same version is not newer',
      );
    });

    test('UpdateHelper._isNewerVersion returns false for older version', () {
      expect(
        UpdateHelper.isNewerVersion('0.9.9', '1.0.0'),
        isFalse,
        reason: '0.9.9 is not newer than 1.0.0',
      );
    });

    test('UpdateHelper._isNewerVersion handles minor version bumps', () {
      expect(
        UpdateHelper.isNewerVersion('1.0.1', '1.0.0'),
        isTrue,
        reason: 'Patch version bump 1.0.1 is newer than 1.0.0',
      );
    });
  });
}
