import 'dart:io';

import 'package:dart_style/dart_style.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

final _dartfmt = new DartFormatter();

/// For the provided [dartFile], ensure the golden file checked-in is updated.
///
/// This looks for the corresponding [checkExtension] file (recently generated
/// by a build system) and compares it to the source-file of [goldenExtension].
void compareCheckFileToGolden(
  String dartFile, {
  @required String checkExtension,
  @required String goldenExtension,
}) {
  final checkPath = p.setExtension(dartFile, checkExtension);
  final goldenPath = p.setExtension(dartFile, goldenExtension);
  final check = _dartfmt.format(new File(checkPath).readAsStringSync());
  final golden = _dartfmt.format(new File(goldenPath).readAsStringSync());
  expect(check, golden, reason: '$goldenPath is out of date. See $checkPath.');
}
