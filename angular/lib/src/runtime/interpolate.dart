/// Functions that are used to process interpolations (e.g. `{{ ... }}`).

/// Fallback for an expression that has more than two successive interpolations.
///
/// ```
/// <!--
///   // Approximately.
///   interpolateN([
///     'Submit ',
///     ctx.name,
///     ' for ',
///     ctx.type,
///     '.',
///   ])
/// -->
/// <button title="Submit {{name}} for {{type}}."></button>
/// ```
String interpolateN(List<Object?> any) {
  var output = '';
  for (var i = 0; i < any.length; i++) {
    final arg = any[i];
    if (arg != null) {
      output += '$arg';
    }
  }
  return output;
}

/// Interpolate a single expression, [any], that could be any type of value.
///
/// If `null`, [any] is treated as `''`.
String interpolate0(Object? any) => any is String
    ? any
    : any == null
        ? ''
        : '$any';

/// Interpolate an expression [v1] in between two static text nodes [v0], [v1].
String interpolate1(
  String v0,
  Object? v1,
  String v2,
) =>
    '$v0${interpolate0(v1)}$v2';

/// Interpolate expressions [v1] and [v3] between static text nodes.
String interpolate2(
  String v0,
  Object? v1,
  String v2,
  Object? v3,
  String v4,
) =>
    interpolate1(interpolate1(v0, v1, v2), v3, v4);

/// Optimization for when the only expression, [v0], is known to be a `String?`.
///
/// TODO(b/168068862): Consider an optimized null-safe variant.
String interpolateString0(String? v0) => v0 ?? '';

/// Optimized version of [interpolate1] when [v1] is known to be a `String?`.
String interpolateString1(
  String v0,
  String? v1,
  String v2,
) =>
    '$v0${interpolateString0(v1)}$v2';

/// Optimized version of [interpolate2] when [v1] and [v3] are a `String?`.
String interpolateString2(
  String v0,
  String? v1,
  String v2,
  String? v3,
  String v4,
) =>
    interpolateString1(interpolateString1(v0, v1, v2), v3, v4);
