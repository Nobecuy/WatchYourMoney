import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:watch_your_money/core/settings/settings_model.dart';

/// Formats monetary amounts according to the active [SettingsData] currency.
///
/// **Instance usage** (reactive):
///   final fmt = CurrencyFormatter.from(settings);
///   fmt.format(amount)
///   fmt.compact(amount)
///
/// **Static usage** (IDR-only fallback for places not yet wired to settings):
///   CurrencyFormatter.formatStatic(amount)
///   CurrencyFormatter.compactStatic(amount)
class CurrencyFormatter {
  const CurrencyFormatter._({
    required this._symbol,
    required this._locale,
    required this._useSuffix,
  });

  final String _symbol;
  final String _locale;
  final bool _useSuffix;

  /// The currency symbol (e.g., "Rp ", "$ ", "€ ", "£ ")
  String get symbol => _symbol;

  // ── IDR singleton used by legacy static API ──────────────────────────────
  static const _idr = CurrencyFormatter._(
    symbol: 'Rp ',
    locale: 'id_ID',
    useSuffix: true,
  );

  // ── Factory ──────────────────────────────────────────────────────────────

  /// Returns a formatter matching the user's currently selected currency.
  factory CurrencyFormatter.from(SettingsData settings) {
    switch (settings.currencyCode) {
      case 'USD':
        return const CurrencyFormatter._(
          symbol: r'$ ',
          locale: 'en_US',
          useSuffix: false,
        );
      case 'EUR':
        return const CurrencyFormatter._(
          symbol: '€ ',
          locale: 'de_DE',
          useSuffix: false,
        );
      case 'GBP':
        return const CurrencyFormatter._(
          symbol: '£ ',
          locale: 'en_GB',
          useSuffix: false,
        );
      default: // IDR
        return _idr;
    }
  }

  // ── Instance API ─────────────────────────────────────────────────────────

  /// Full formatted amount, e.g. "Rp 1.500.000" or "$1,500".
  String format(double amount) {
    return NumberFormat.currency(
      locale: _locale,
      symbol: _symbol,
      decimalDigits: 0,
    ).format(amount);
  }

  /// Abbreviated. IDR: "Rp 1.5jt" / "Rp 500rb" | others: "$1.5M" / "$500K"
  String compact(double amount) {
    final sym = _symbol.trim();
    if (_useSuffix) {
      if (amount >= 1000000) {
        return '$sym ${(amount / 1000000).toStringAsFixed(1)}jt';
      }
      if (amount >= 1000) {
        return '$sym ${(amount / 1000).toStringAsFixed(0)}rb';
      }
      return format(amount);
    } else {
      if (amount >= 1000000) {
        return '$sym${(amount / 1000000).toStringAsFixed(1)}M';
      }
      if (amount >= 1000) {
        return '$sym${(amount / 1000).toStringAsFixed(1)}K';
      }
      return format(amount);
    }
  }

  // ── Legacy static API (IDR only) ─────────────────────────────────────────

  /// Formats [amount] as IDR. Prefer [CurrencyFormatter.from] for reactive currency.
  static String formatStatic(double amount) => _idr.format(amount);

  /// Compact IDR format. Prefer [CurrencyFormatter.from] for reactive currency.
  static String compactStatic(double amount) => _idr.compact(amount);
}

/// [TextInputFormatter] that adds thousand separators (dots) as the user types.
/// Uses Indonesian format (dots for thousands, no decimals for IDR).
class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  final String separator;

  const ThousandsSeparatorInputFormatter({this.separator = '.'});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // If the new value is empty, allow it
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Remove all non-digit characters
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    // If nothing left after removing non-digits, allow empty
    if (digitsOnly.isEmpty) {
      return TextEditingValue.empty;
    }

    // Format with thousand separators
    final formatted = _addSeparators(digitsOnly);

    // Calculate new cursor position
    // We try to maintain the cursor's relative position from the right end
    int newCursorPosition = formatted.length;
    if (oldValue.text.isNotEmpty) {
      final oldDigitsOnly = oldValue.text.replaceAll(RegExp(r'[^\d]'), '');
      final oldFormatted = _addSeparators(oldDigitsOnly);

      // Calculate how many digits were to the right of cursor in old value
      final oldCursorOffsetFromRight = oldFormatted.length - oldValue.selection.baseOffset;

      // Position cursor the same distance from right in new formatted value
      newCursorPosition = formatted.length - oldCursorOffsetFromRight;
      newCursorPosition = newCursorPosition.clamp(0, formatted.length);
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: newCursorPosition),
    );
  }

  String _addSeparators(String digits) {
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      final remaining = digits.length - i;
      if (remaining % 3 == 0 && i != 0) {
        buffer.write(separator);
      }
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }
}

/// Extension to easily get numeric value from a formatted string
extension NumericValue on String {
  /// Returns the numeric value by removing thousand separators
  double get numericValue => double.tryParse(replaceAll(RegExp(r'[^\d]'), '')) ?? 0;
}
