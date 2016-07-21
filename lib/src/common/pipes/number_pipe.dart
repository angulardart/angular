import "package:angular2/core.dart" show Injectable, PipeTransform, Pipe;
import "package:angular2/src/facade/exceptions.dart" show BaseException;
import "package:angular2/src/facade/intl.dart"
    show NumberFormatter, NumberFormatStyle;
import "package:angular2/src/facade/lang.dart"
    show isNumber, isPresent, isBlank, NumberWrapper, RegExpWrapper;

import "invalid_pipe_argument_exception.dart" show InvalidPipeArgumentException;

String defaultLocale = "en-US";
var _re = RegExpWrapper.create("^(\\d+)?\\.((\\d+)(\\-(\\d+))?)?\$");

/**
 * Internal base class for numeric pipes.
 */
@Injectable()
class NumberPipe {
  /** @internal */
  static String _format(num value, NumberFormatStyle style, String digits,
      [String currency = null, bool currencyAsSymbol = false]) {
    if (isBlank(value)) return null;
    if (!isNumber(value)) {
      throw new InvalidPipeArgumentException(NumberPipe, value);
    }
    var minInt = 1, minFraction = 0, maxFraction = 3;
    if (isPresent(digits)) {
      var parts = RegExpWrapper.firstMatch(_re, digits);
      if (isBlank(parts)) {
        throw new BaseException(
            '''${ digits} is not a valid digit info for number pipes''');
      }
      if (isPresent(parts[1])) {
        minInt = NumberWrapper.parseIntAutoRadix(parts[1]);
      }
      if (isPresent(parts[3])) {
        minFraction = NumberWrapper.parseIntAutoRadix(parts[3]);
      }
      if (isPresent(parts[5])) {
        maxFraction = NumberWrapper.parseIntAutoRadix(parts[5]);
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

/**
 * WARNING: this pipe uses the Internationalization API.
 * Therefore it is only reliable in Chrome and Opera browsers.
 *
 * Formats a number as local text. i.e. group sizing and separator and other locale-specific
 * configurations are based on the active locale.
 *
 * ### Usage
 *
 *     expression | number[:digitInfo]
 *
 * where `expression` is a number and `digitInfo` has the following format:
 *
 *     {minIntegerDigits}.{minFractionDigits}-{maxFractionDigits}
 *
 * - minIntegerDigits is the minimum number of integer digits to use. Defaults to 1.
 * - minFractionDigits is the minimum number of digits after fraction. Defaults to 0.
 * - maxFractionDigits is the maximum number of digits after fraction. Defaults to 3.
 *
 * For more information on the acceptable range for each of these numbers and other
 * details see your native internationalization library.
 *
 * ### Example
 *
 * {@example core/pipes/ts/number_pipe/number_pipe_example.ts region='NumberPipe'}
 */
@Pipe(name: "number")
@Injectable()
class DecimalPipe extends NumberPipe implements PipeTransform {
  String transform(dynamic value, [String digits = null]) {
    return NumberPipe._format(value, NumberFormatStyle.Decimal, digits);
  }

  const DecimalPipe();
}

/**
 * WARNING: this pipe uses the Internationalization API.
 * Therefore it is only reliable in Chrome and Opera browsers.
 *
 * Formats a number as local percent.
 *
 * ### Usage
 *
 *     expression | percent[:digitInfo]
 *
 * For more information about `digitInfo` see [DecimalPipe]
 *
 * ### Example
 *
 * {@example core/pipes/ts/number_pipe/number_pipe_example.ts region='PercentPipe'}
 */
@Pipe(name: "percent")
@Injectable()
class PercentPipe extends NumberPipe implements PipeTransform {
  String transform(dynamic value, [String digits = null]) {
    return NumberPipe._format(value, NumberFormatStyle.Percent, digits);
  }

  const PercentPipe();
}

/**
 * WARNING: this pipe uses the Internationalization API.
 * Therefore it is only reliable in Chrome and Opera browsers.
 *
 * Formats a number as local currency.
 *
 * ### Usage
 *
 *     expression | currency[:currencyCode[:symbolDisplay[:digitInfo]]]
 *
 * where `currencyCode` is the ISO 4217 currency code, such as "USD" for the US dollar and
 * "EUR" for the euro. `symbolDisplay` is a boolean indicating whether to use the currency
 * symbol (e.g. $) or the currency code (e.g. USD) in the output. The default for this value
 * is `false`.
 * For more information about `digitInfo` see [DecimalPipe]
 *
 * ### Example
 *
 * {@example core/pipes/ts/number_pipe/number_pipe_example.ts region='CurrencyPipe'}
 */
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
