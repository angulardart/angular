import 'dart:math' as math;

import 'package:angular2/di.dart' show Injectable, PipeTransform, Pipe;

import 'invalid_pipe_argument_exception.dart' show InvalidPipeArgumentException;

/// Creates a new List or String containing only a subset (slice) of the
/// elements.
///
/// The starting index of the subset to return is specified by the `start`
/// parameter.
///
/// The ending index of the subset to return is specified by the optional `end`
/// parameter.
///
/// ### Usage
///
///     expression | slice:start[:end]
///
/// All behavior is based on the expected behavior of the JavaScript API
/// Array.prototype.slice() and String.prototype.slice()
///
/// Where the input expression is a [List] or [String], and `start` is:
///
/// - **a positive integer**: return the item at _start_ index and all items
/// after in the list or string expression.
/// - **a negative integer**: return the item at _start_ index from the end and
/// all items after in the list or string expression.
/// - **`|start|` greater than the size of the expression**: return an empty
/// list or string.
/// - **`|start|` negative greater than the size of the expression**: return
/// entire list or string expression.
///
/// and where `end` is:
///
/// - **omitted**: return all items until the end of the input
/// - **a positive integer**: return all items before _end_ index of the list or
/// string expression.
/// - **a negative integer**: return all items before _end_ index from the end
/// of the list or string expression.
///
/// When operating on a [List], the returned list is always a copy even when all
/// the elements are being returned.
///
/// ## List Example
///
/// This `ngFor` example:
///
/// {@example core/pipes/ts/slice_pipe/slice_pipe_example.ts region='SlicePipe_list'}
///
/// produces the following:
///
///     <li>b</li>
///     <li>c</li>
@Pipe(name: "slice", pure: false)
@Injectable()
class SlicePipe implements PipeTransform {
  dynamic transform(dynamic value, num start, [num end = null]) {
    if (!this.supports(value)) {
      throw new InvalidPipeArgumentException(SlicePipe, value);
    }
    if (value == null) return value;
    // This used to have JS behavior with TS-transpiled facades. To avoid a
    // breaking change, we inline the behavior here and will cleanup after all
    // facades are removed.
    int length = value.length as int;
    start = start < 0 ? math.max(0, length + start) : math.min(start, length);
    if (end != null) {
      end = end < 0 ? math.max(0, length + end) : math.min(end, length);
      if (end < start) return value is String ? '' : [];
    }
    if (value is String) {
      return value.substring(start, end);
    } else if (value is List) {
      return value.sublist(start, end);
    } else {
      return null;
    }
  }

  bool supports(dynamic obj) => obj is String || obj is List;
}
