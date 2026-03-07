import 'package:intl/intl.dart';

/// Centralized money formatting for the app.
///
/// Backend prices/balances in this project are already in VND (e.g. 35000).
/// Use [vnd] to format them with Vietnamese separators.
class Money {
  static final NumberFormat _vndFormatter = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );

  static String vnd(num amountVnd) => _vndFormatter.format(amountVnd);

  @Deprecated('Prices are already VND; use Money.vnd(amount)')
  static String vndFromUsd(num amountUsd) => vnd(amountUsd);
}
