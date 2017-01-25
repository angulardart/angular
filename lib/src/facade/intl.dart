import 'package:intl/intl.dart';

String _normalizeLocale(String locale) => locale.replaceAll('-', '_');

@Deprecated('Being removed from the public API, only usable via NumberPipe')
enum NumberFormatStyle { Decimal, Percent, Currency }

@Deprecated('Being removed from the public API, only usable via NumberPipe')
class NumberFormatter {
  @Deprecated('Being removed from the public API, only usable via NumberPipe')
  static String format(
    num number,
    String locale,
    NumberFormatStyle style, {
    int minimumIntegerDigits: 1,
    int minimumFractionDigits: 0,
    int maximumFractionDigits: 3,
    String currency,
    bool currencyAsSymbol: false,
  }) {
    return formatNumber(
      number,
      locale,
      style,
      minimumIntegerDigits: minimumIntegerDigits,
      minimumFractionDigits: minimumFractionDigits,
      maximumFractionDigits: maximumFractionDigits,
      currency: currency,
      currencyAsSymbol: currencyAsSymbol,
    );
  }
}

// Internal API, will only be used to keep NumberPipe functioning.
String formatNumber(
  num number,
  String locale,
  NumberFormatStyle style, {
  int minimumIntegerDigits: 1,
  int minimumFractionDigits: 0,
  int maximumFractionDigits: 3,
  String currency,
  bool currencyAsSymbol: false,
}) {
  locale = _normalizeLocale(locale);
  NumberFormat formatter;
  switch (style) {
    case NumberFormatStyle.Decimal:
      formatter = new NumberFormat.decimalPattern(locale);
      break;
    case NumberFormatStyle.Percent:
      formatter = new NumberFormat.percentPattern(locale);
      break;
    case NumberFormatStyle.Currency:
      if (currencyAsSymbol) {
        formatter =
            new NumberFormat.simpleCurrency(locale: locale, name: currency);
      } else {
        formatter = new NumberFormat.currency(locale: locale, name: currency);
      }
      break;
  }
  formatter.minimumIntegerDigits = minimumIntegerDigits;
  formatter.minimumFractionDigits = minimumFractionDigits;
  formatter.maximumFractionDigits = maximumFractionDigits;
  return formatter.format(number);
}

// Internal API, will only be used to keep DatePipe functioning.
final RegExp _multiPartRegExp = new RegExp(r'^([yMdE]+)([Hjms]+)$');
String formatDate(DateTime date, String locale, String pattern) {
  locale = _normalizeLocale(locale);
  var formatter = new DateFormat(null, locale);
  var matches = _multiPartRegExp.firstMatch(pattern);
  if (matches != null) {
    // Support for patterns which have known date and time components.
    formatter.addPattern(matches[1]);
    formatter.addPattern(matches[2], ', ');
  } else {
    formatter.addPattern(pattern);
  }
  return formatter.format(date);
}

@Deprecated('Being removed from the public API, only usable via DatePipe')
class DateFormatter {
  @Deprecated('Being removed, only usable via DatePipe')
  static String format(DateTime date, String locale, String pattern) {
    return formatDate(date, locale, pattern);
  }
}
