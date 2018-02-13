import 'package:intl/intl.dart';
import 'package:angular/core.dart';

import 'invalid_pipe_argument_exception.dart';

// TODO: Remove the following lines (for --no-implicit-casts).
// ignore_for_file: argument_type_not_assignable
// ignore_for_file: invalid_assignment

/// Formats a date value to a string based on the requested format.
///
/// WARNINGS:
/// - this pipe is marked as pure hence it will not be re-evaluated when the
///   input is mutated. Instead users should treat the date as an immutable
///   object and change the reference when the pipe needs to re-run (this is to
///   avoid reformatting the date on every change detection run which would be
///   an expensive operation).
/// - this pipe uses the Internationalization API. Therefore it is only reliable
///   in Chrome and Opera browsers.
///
/// ## Usage
///
///     expression | date[:format]
///
/// where `expression` is a date object or a number (milliseconds since UTC
/// epoch) and `format` indicates which date/time components to include:
///
///  | Component | Symbol | Short Form   | Long Form         | Numeric   | 2-digit   |
///  |-----------|:------:|--------------|-------------------|-----------|-----------|
///  | era       |   G    | G (AD)       | GGGG (Anno Domini)| -         | -         |
///  | year      |   y    | -            | -                 | y (2015)  | yy (15)   |
///  | month     |   M    | MMM (Sep)    | MMMM (September)  | M (9)     | MM (09)   |
///  | day       |   d    | -            | -                 | d (3)     | dd (03)   |
///  | weekday   |   E    | EEE (Sun)    | EEEE (Sunday)     | -         | -         |
///  | hour      |   j    | -            | -                 | j (13)    | jj (13)   |
///  | hour12    |   h    | -            | -                 | h (1 PM)  | hh (01 PM)|
///  | hour24    |   H    | -            | -                 | H (13)    | HH (13)   |
///  | minute    |   m    | -            | -                 | m (5)     | mm (05)   |
///  | second    |   s    | -            | -                 | s (9)     | ss (09)   |
///  | timezone  |   z    | -            | z (Pacific Standard Time)| -  | -         |
///  | timezone  |   Z    | Z (GMT-8:00) | -                 | -         | -         |
///
/// In javascript, only the components specified will be respected (not the
/// ordering, punctuations, ...) and details of the formatting will be dependent
/// on the locale.
/// On the other hand in Dart version, you can also include quoted text as well
/// as some extra date/time components such as quarter. For more information see:
/// https://api.dartlang.org/apidocs/channels/stable/dartdoc-viewer/intl/intl.DateFormat.
///
/// `format` can also be one of the following predefined formats:
///
///  - `'medium'`: equivalent to `'yMMMdjms'` (e.g. Sep 3, 2010, 12:05:08 PM for en-US)
///  - `'short'`: equivalent to `'yMdjm'` (e.g. 9/3/2010, 12:05 PM for en-US)
///  - `'fullDate'`: equivalent to `'yMMMMEEEEd'` (e.g. Friday, September 3, 2010 for en-US)
///  - `'longDate'`: equivalent to `'yMMMMd'` (e.g. September 3, 2010)
///  - `'mediumDate'`: equivalent to `'yMMMd'` (e.g. Sep 3, 2010 for en-US)
///  - `'shortDate'`: equivalent to `'yMd'` (e.g. 9/3/2010 for en-US)
///  - `'mediumTime'`: equivalent to `'jms'` (e.g. 12:05:08 PM for en-US)
///  - `'shortTime'`: equivalent to `'jm'` (e.g. 12:05 PM for en-US)
///
/// Timezone of the formatted text will be the local system timezone of the
/// end-users machine.
///
/// ### Examples
///
/// Assuming `dateObj` is (year: 2015, month: 6, day: 15, hour: 21, minute: 43,
/// second: 11) in the _local_ time and locale is 'en-US':
///
///     {{ dateObj | date }}             // output is 'Jun 15, 2015'
///     {{ dateObj | date:'medium' }}    // output is 'Jun 15, 2015, 9:43:11 PM'
///     {{ dateObj | date:'shortTime' }} // output is '9:43 PM'
///     {{ dateObj | date:'mmss' }}      // output is '43:11'
@Pipe('date', pure: true)
class DatePipe implements PipeTransform {
  static final Map<String, String> _ALIASES = {
    'medium': 'yMMMdjms',
    'short': 'yMdjm',
    'fullDate': 'yMMMMEEEEd',
    'longDate': 'yMMMMd',
    'mediumDate': 'yMMMd',
    'shortDate': 'yMd',
    'mediumTime': 'jms',
    'shortTime': 'jm'
  };
  String transform(dynamic value, [String pattern = 'mediumDate']) {
    if (value == null) return null;
    if (!this.supports(value)) {
      throw new InvalidPipeArgumentException(DatePipe, value);
    }
    if (value is num) {
      value = new DateTime.fromMillisecondsSinceEpoch(value);
    }
    if (DatePipe._ALIASES.containsKey(pattern)) {
      pattern = DatePipe._ALIASES[pattern];
    }
    return _formatDate(value, Intl.defaultLocale, pattern);
  }

  bool supports(dynamic obj) {
    return obj is DateTime || obj is num;
  }

  const DatePipe();
}

final RegExp _multiPartRegExp = new RegExp(r'^([yMdE]+)([Hjms]+)$');
String _normalizeLocale(String locale) => locale?.replaceAll('-', '_');
String _formatDate(DateTime date, String locale, String pattern) {
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
