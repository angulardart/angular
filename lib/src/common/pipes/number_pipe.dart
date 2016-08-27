import "package:angular2/di.dart" show Injectable, PipeTransform, Pipe;
import "package:angular2/src/facade/exceptions.dart" show BaseException;
import "package:angular2/src/facade/intl.dart"
    show NumberFormatter, NumberFormatStyle;

import "invalid_pipe_argument_exception.dart" show InvalidPipeArgumentException;

String defaultLocale = "en-US";
final RegExp _re = new RegExp("^(\\d+)?\\.((\\d+)(\\-(\\d+))?)?\$");

/// Internal base class for numeric pipes.
@Injectable()
class NumberPipe {
  static String _format(num value, NumberFormatStyle style, String digits,
      [String currency = null, bool currencyAsSymbol = false]) {
    if (value == null) return null;
    if (value is! num) {
      throw new InvalidPipeArgumentException(NumberPipe, value);
    }
    var minInt = 1, minFraction = 0, maxFraction = 3;
    if (digits != null) {
      var parts = _re.firstMatch(digits);
      if (parts == null) {
        throw new BaseException(
            '''${ digits} is not a valid digit info for number pipes''');
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
    return NumberFormatter.format(value, defaultLocale, style,
        minimumIntegerDigits: minInt,
        minimumFractionDigits: minFraction,
        maximumFractionDigits: maxFraction,
        currency: currency,
        currencyAsSymbol: currencyAsSymbol);
  }

  const NumberPipe();
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
@Pipe(name: "number")
@Injectable()
class DecimalPipe extends NumberPipe implements PipeTransform {
  String transform(dynamic value, [String digits = null]) {
    return NumberPipe._format(value, NumberFormatStyle.Decimal, digits);
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
@Pipe(name: "percent")
@Injectable()
class PercentPipe extends NumberPipe implements PipeTransform {
  String transform(dynamic value, [String digits = null]) {
    return NumberPipe._format(value, NumberFormatStyle.Percent, digits);
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
@Pipe(name: "currency")
@Injectable()
class CurrencyPipe extends NumberPipe implements PipeTransform {
  String transform(dynamic value,
      [String currencyCode = "USD",
      bool symbolDisplay = false,
      String digits = null]) {
    return NumberPipe._format(
        value, NumberFormatStyle.Currency, digits, currencyCode, symbolDisplay);
  }

  const CurrencyPipe();
}
