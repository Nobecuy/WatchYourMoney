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
