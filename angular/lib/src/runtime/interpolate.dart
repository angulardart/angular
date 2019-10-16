/// A set of functions to support text interpolation in generated views.
import 'package:angular/src/security/dom_sanitization_service.dart';

dynamic interpolate0(dynamic p) {
  if (p is String) return p;
  if (p is SafeValue) return p;
  return p == null ? '' : '$p';
}

String interpolate1(String c0, dynamic a1, String c1) =>
    c0 + (a1 == null ? '' : '$a1') + c1;

String interpolate2(String c0, dynamic a1, String c1, dynamic a2, String c2) =>
    c0 + _toStringWithNull(a1) + c1 + _toStringWithNull(a2) + c2;

String interpolate3(
  String c0,
  dynamic a1,
  String c1,
  dynamic a2,
  String c2,
  dynamic a3,
  String c3,
) =>
    c0 +
    _toStringWithNull(a1) +
    c1 +
    _toStringWithNull(a2) +
    c2 +
    _toStringWithNull(a3) +
    c3;

String interpolate4(
  String c0,
  dynamic a1,
  String c1,
  dynamic a2,
  String c2,
  dynamic a3,
  String c3,
  dynamic a4,
  String c4,
) =>
    c0 +
    _toStringWithNull(a1) +
    c1 +
    _toStringWithNull(a2) +
    c2 +
    _toStringWithNull(a3) +
    c3 +
    _toStringWithNull(a4) +
    c4;

String interpolate5(
  String c0,
  dynamic a1,
  String c1,
  dynamic a2,
  String c2,
  dynamic a3,
  String c3,
  dynamic a4,
  String c4,
  dynamic a5,
  String c5,
) =>
    c0 +
    _toStringWithNull(a1) +
    c1 +
    _toStringWithNull(a2) +
    c2 +
    _toStringWithNull(a3) +
    c3 +
    _toStringWithNull(a4) +
    c4 +
    _toStringWithNull(a5) +
    c5;

String interpolate6(
  String c0,
  dynamic a1,
  String c1,
  dynamic a2,
  String c2,
  dynamic a3,
  String c3,
  dynamic a4,
  String c4,
  dynamic a5,
  String c5,
  dynamic a6,
  String c6,
) =>
    c0 +
    _toStringWithNull(a1) +
    c1 +
    _toStringWithNull(a2) +
    c2 +
    _toStringWithNull(a3) +
    c3 +
    _toStringWithNull(a4) +
    c4 +
    _toStringWithNull(a5) +
    c5 +
    _toStringWithNull(a6) +
    c6;

String interpolate7(
  String c0,
  dynamic a1,
  String c1,
  dynamic a2,
  String c2,
  dynamic a3,
  String c3,
  dynamic a4,
  String c4,
  dynamic a5,
  String c5,
  dynamic a6,
  String c6,
  dynamic a7,
  String c7,
) =>
    c0 +
    _toStringWithNull(a1) +
    c1 +
    _toStringWithNull(a2) +
    c2 +
    _toStringWithNull(a3) +
    c3 +
    _toStringWithNull(a4) +
    c4 +
    _toStringWithNull(a5) +
    c5 +
    _toStringWithNull(a6) +
    c6 +
    _toStringWithNull(a7) +
    c7;

String interpolate8(
  String c0,
  dynamic a1,
  String c1,
  dynamic a2,
  String c2,
  dynamic a3,
  String c3,
  dynamic a4,
  String c4,
  dynamic a5,
  String c5,
  dynamic a6,
  String c6,
  dynamic a7,
  String c7,
  dynamic a8,
  String c8,
) =>
    c0 +
    _toStringWithNull(a1) +
    c1 +
    _toStringWithNull(a2) +
    c2 +
    _toStringWithNull(a3) +
    c3 +
    _toStringWithNull(a4) +
    c4 +
    _toStringWithNull(a5) +
    c5 +
    _toStringWithNull(a6) +
    c6 +
    _toStringWithNull(a7) +
    c7 +
    _toStringWithNull(a8) +
    c8;

String interpolate9(
  String c0,
  dynamic a1,
  String c1,
  dynamic a2,
  String c2,
  dynamic a3,
  String c3,
  dynamic a4,
  String c4,
  dynamic a5,
  String c5,
  dynamic a6,
  String c6,
  dynamic a7,
  String c7,
  dynamic a8,
  String c8,
  dynamic a9,
  String c9,
) =>
    c0 +
    _toStringWithNull(a1) +
    c1 +
    _toStringWithNull(a2) +
    c2 +
    _toStringWithNull(a3) +
    c3 +
    _toStringWithNull(a4) +
    c4 +
    _toStringWithNull(a5) +
    c5 +
    _toStringWithNull(a6) +
    c6 +
    _toStringWithNull(a7) +
    c7 +
    _toStringWithNull(a8) +
    c8 +
    _toStringWithNull(a9) +
    c9;

String _toStringWithNull(dynamic v) => v == null ? '' : '$v';

/// String version of interpolate

String interpolateString0(String p) => _stringOrNull(p);

String interpolateString1(String c0, String a1, String c1) =>
    c0 + _stringOrNull(a1) + c1;

String interpolateString2(
        String c0, String a1, String c1, String a2, String c2) =>
    c0 + _stringOrNull(a1) + c1 + _stringOrNull(a2) + c2;

String interpolateString3(
  String c0,
  String a1,
  String c1,
  String a2,
  String c2,
  String a3,
  String c3,
) =>
    c0 +
    _stringOrNull(a1) +
    c1 +
    _stringOrNull(a2) +
    c2 +
    _stringOrNull(a3) +
    c3;

String interpolateString4(
  String c0,
  String a1,
  String c1,
  String a2,
  String c2,
  String a3,
  String c3,
  String a4,
  String c4,
) =>
    c0 +
    _stringOrNull(a1) +
    c1 +
    _stringOrNull(a2) +
    c2 +
    _stringOrNull(a3) +
    c3 +
    _stringOrNull(a4) +
    c4;

String interpolateString5(
  String c0,
  String a1,
  String c1,
  String a2,
  String c2,
  String a3,
  String c3,
  String a4,
  String c4,
  String a5,
  String c5,
) =>
    c0 +
    _stringOrNull(a1) +
    c1 +
    _stringOrNull(a2) +
    c2 +
    _stringOrNull(a3) +
    c3 +
    _stringOrNull(a4) +
    c4 +
    _stringOrNull(a5) +
    c5;

String interpolateString6(
  String c0,
  String a1,
  String c1,
  String a2,
  String c2,
  String a3,
  String c3,
  String a4,
  String c4,
  String a5,
  String c5,
  String a6,
  String c6,
) =>
    c0 +
    _stringOrNull(a1) +
    c1 +
    _stringOrNull(a2) +
    c2 +
    _stringOrNull(a3) +
    c3 +
    _stringOrNull(a4) +
    c4 +
    _stringOrNull(a5) +
    c5 +
    _stringOrNull(a6) +
    c6;

String interpolateString7(
  String c0,
  String a1,
  String c1,
  String a2,
  String c2,
  String a3,
  String c3,
  String a4,
  String c4,
  String a5,
  String c5,
  String a6,
  String c6,
  String a7,
  String c7,
) =>
    c0 +
    _stringOrNull(a1) +
    c1 +
    _stringOrNull(a2) +
    c2 +
    _stringOrNull(a3) +
    c3 +
    _stringOrNull(a4) +
    c4 +
    _stringOrNull(a5) +
    c5 +
    _stringOrNull(a6) +
    c6 +
    _stringOrNull(a7) +
    c7;

String interpolateString8(
  String c0,
  String a1,
  String c1,
  String a2,
  String c2,
  String a3,
  String c3,
  String a4,
  String c4,
  String a5,
  String c5,
  String a6,
  String c6,
  String a7,
  String c7,
  String a8,
  String c8,
) =>
    c0 +
    _stringOrNull(a1) +
    c1 +
    _stringOrNull(a2) +
    c2 +
    _stringOrNull(a3) +
    c3 +
    _stringOrNull(a4) +
    c4 +
    _stringOrNull(a5) +
    c5 +
    _stringOrNull(a6) +
    c6 +
    _stringOrNull(a7) +
    c7 +
    _stringOrNull(a8) +
    c8;

String interpolateString9(
  String c0,
  String a1,
  String c1,
  String a2,
  String c2,
  String a3,
  String c3,
  String a4,
  String c4,
  String a5,
  String c5,
  String a6,
  String c6,
  String a7,
  String c7,
  String a8,
  String c8,
  String a9,
  String c9,
) =>
    c0 +
    _stringOrNull(a1) +
    c1 +
    _stringOrNull(a2) +
    c2 +
    _stringOrNull(a3) +
    c3 +
    _stringOrNull(a4) +
    c4 +
    _stringOrNull(a5) +
    c5 +
    _stringOrNull(a6) +
    c6 +
    _stringOrNull(a7) +
    c7 +
    _stringOrNull(a8) +
    c8 +
    _stringOrNull(a9) +
    c9;

String _stringOrNull(String v) => v ?? '';
