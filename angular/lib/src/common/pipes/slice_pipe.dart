import 'dart:math' as math;

import 'package:angular/src/meta.dart';

import 'invalid_pipe_argument_exception.dart' show InvalidPipeArgumentException;

/// Creates a new [List] or [String] containing a subset (slice) of the
/// elements.
///
/// ### Usage
///
///     $pipe.slice(expression, start, [end])
///
/// The input _expression_ must be a [List] or [String].
///
/// - _start_: the starting index of the subset to return.
///   - **a positive integer**: return the item at `start` index and all
///     items after in the list or string expression.
///   - **a negative integer**: return the item at `start` index from the end
///     and all items after in the list or string expression.
///   - **if positive and greater than the size of the expression**:
///     return an empty list or string.
///   - **if negative and greater than the size of the expression**:
///     return entire list or string.
/// - _end_: The ending index of the subset to return.
///   - **omitted**: return all items until the end.
///   - **if positive**: return all items before `end` index of the list or
///     string.
///   - **if negative**: return all items before `end` index
///     from the end of the list or string.
///
/// When operating on a [List], the returned list is always a copy even when all
/// the elements are being returned.
///
/// ### Examples
///
/// <?code-excerpt "common/pipes/lib/app_component.html (slice)"?>
/// ```html
/// <ul>
///     <li *ngFor="let i of $pipe.slice(['a', 'b', 'c', 'd'], 1, 3)">{{i}}</li>
/// </ul>
///
/// <pre>
///   {{str}}[0:4]:   '$pipe.slice(str, 0, 4)}}' --> 'abcd'
///   {{str}}[4:0]:   '$pipe.slice(str, 4, 0)}}' --> ''
///   {{str}}[-4]:    '$pipe.slice(str, -4)}}' --> 'ghij'
///   {{str}}[-4:-2]: '$pipe.slice(str, -4, -2)}}' --> 'gh'
///   {{str}}[-100]:  '$pipe.slice(str, -100)}}' --> 'abcdefghij'
///   {{str}}[100]:   '$pipe.slice(str, 100)}}' --> ''
/// </pre>
/// ```
/// The first example generates two `<li>` elements with text `b` and `c`.
/// The second example uses the string `'abcdefghij'`.
@Pipe('slice', pure: false)
class SlicePipe {
  dynamic transform(dynamic value, int start, [int? end]) {
    if (value == null) return value;
    if (!supports(value)) {
      throw InvalidPipeArgumentException(SlicePipe, value);
    }
    // This used to have JS behavior with TS-transpiled facades. To avoid a
    // breaking change, we inline the behavior here and will cleanup after all
    // facades are removed.
    var length = value.length as int;
    start = start < 0 ? math.max(0, length + start) : math.min(start, length);
    if (end != null) {
      end = end < 0 ? math.max(0, length + end) : math.min(end, length);
      if (end < start) return value is String ? '' : <Object>[];
    }
    if (value is String) {
      return value.substring(start, end);
    } else if (value is List<Object?>) {
      return value.sublist(start, end);
    } else {
      return null;
    }
  }

  bool supports(dynamic obj) => obj is String || obj is List<Object?>;
}
