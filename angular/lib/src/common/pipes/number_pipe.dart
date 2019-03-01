import 'package:intl/intl.dart';
import 'package:angular/core.dart' show PipeTransform, Pipe;

import 'invalid_pipe_argument_exception.dart';

final RegExp _re = RegExp("^(\\d+)?\\.((\\d+)(\\-(\\d+))?)?\$");

/// Internal base class for numeric pipes.
class _NumberPipe {
  static String _format(num value, _NumberFormatStyle style, String digits,
      [String currency, bool currencyAsSymbol = false]) {
    if (value == null) return null;
    if (value is! num) {
      throw InvalidPipeArgumentException(_NumberPipe, value);
    }
    var minInt = 1, minFraction = 0, maxFraction = 3;
    if (digits != null) {
      var parts = _re.firstMatch(digits);
      if (parts == null) {
        throw FormatException(
          '$digits is not a valid digit info for number pipes',
        );
      }
      if (parts[1] != null) {
        minInt = int.parse(parts[1]);
      }
      if (parts[3] != null) {
        minFraction = int.parse(parts[3]);
      }
      if (parts[5] != null) {
        maxFraction = int.parse(parts[5]);
      }
    }
    return _formatNumber(
      value,
      Intl.defaultLocale,
      style,
      minimumIntegerDigits: minInt,
      minimumFractionDigits: minFraction,
      maximumFractionDigits: maxFraction,
      currency: currency,
      currencyAsSymbol: currencyAsSymbol,
    );
  }

  const _NumberPipe();
}

/// WARNING: this pipe uses the Internationalization API.
/// Therefore it is only reliable in Chrome and Opera browsers.
///
/// Formats a number as local text. i.e. group sizing and separator and other locale-specific
/// configurations are based on the active locale.
///
/// ### Usage
///
///     expression | number[:digitInfo]
///
/// where `expression` is a number and `digitInfo` has the following format:
///
///     {minIntegerDigits}.{minFractionDigits}-{maxFractionDigits}
///
/// - minIntegerDigits is the minimum number of integer digits to use. Defaults to 1.
/// - minFractionDigits is the minimum number of digits after fraction. Defaults to 0.
/// - maxFractionDigits is the maximum number of digits after fraction. Defaults to 3.
///
/// For more information on the acceptable range for each of these numbers and other
/// details see your native internationalization library.
@Pipe('number')
class DecimalPipe extends _NumberPipe implements PipeTransform {
  String transform(num value, [String digits]) {
    return _NumberPipe._format(value, _NumberFormatStyle.Decimal, digits);
  }

  const DecimalPipe();
}

/// WARNING: this pipe uses the Internationalization API.
/// Therefore it is only reliable in Chrome and Opera browsers.
///
/// Formats a number as local percent.
///
/// ### Usage
///
///     expression | percent[:digitInfo]
///
/// For more information about `digitInfo` see [DecimalPipe]
@Pipe('percent')
class PercentPipe extends _NumberPipe implements PipeTransform {
  String transform(num value, [String digits]) {
    return _NumberPipe._format(value, _NumberFormatStyle.Percent, digits);
  }

  const PercentPipe();
}

/// WARNING: this pipe uses the Internationalization API.
/// Therefore it is only reliable in Chrome and Opera browsers.
///
/// Formats a number as local currency.
///
/// ### Usage
///
///     expression | currency[:currencyCode[:symbolDisplay[:digitInfo]]]
///
/// where `currencyCode` is the ISO 4217 currency code, such as "USD" for the
/// US dollar and "EUR" for the euro. `symbolDisplay` is a boolean indicating
/// whether to use the currency symbol (e.g. $) or the currency code (e.g. USD)
/// in the output. The default for this value is `false`.
/// For more information about `digitInfo` see [DecimalPipe]
@Pipe('currency')
class CurrencyPipe extends _NumberPipe implements PipeTransform {
  String transform(
    num value, [
    String currencyCode = 'USD',
    bool symbolDisplay = false,
    String digits,
  ]) =>
      _NumberPipe._format(
        value,
        _NumberFormatStyle.Currency,
        digits,
        currencyCode,
        symbolDisplay,
      );

  const CurrencyPipe();
}

enum _NumberFormatStyle { Decimal, Percent, Currency }
String _normalizeLocale(String locale) => locale?.replaceAll('-', '_');
String _formatNumber(
  num number,
  String locale,
  _NumberFormatStyle style, {
  int minimumIntegerDigits = 1,
  int minimumFractionDigits = 0,
  int maximumFractionDigits = 3,
  String currency,
  bool currencyAsSymbol = false,
}) {
  locale = _normalizeLocale(locale);
  NumberFormat formatter;
  switch (style) {
    case _NumberFormatStyle.Decimal:
      formatter = NumberFormat.decimalPattern(locale);
      break;
    case _NumberFormatStyle.Percent:
      formatter = NumberFormat.percentPattern(locale);
      break;
    case _NumberFormatStyle.Currency:
      if (currencyAsSymbol) {
        formatter = NumberFormat.simpleCurrency(locale: locale, name: currency);
      } else {
        formatter = NumberFormat.currency(locale: locale, name: currency);
      }
      break;
  }
  formatter.minimumIntegerDigits = minimumIntegerDigits;
  formatter.minimumFractionDigits = minimumFractionDigits;
  formatter.maximumFractionDigits = maximumFractionDigits;
  return formatter.format(number);
}
