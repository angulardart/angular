import 'dart:io';

import 'package:dart_style/dart_style.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

final _dartfmt = DartFormatter();

/// For the provided [dartFile], ensure the golden file checked-in is updated.
///
/// This looks for the corresponding [checkExtension] file (recently generated
/// by a build system) and compares it to the source-file of [goldenExtension].
void compareCheckFileToGolden(
  String dartFile, {
  bool formatDart = true,
  @required String checkExtension,
  @required String goldenExtension,
}) {
  // Skip the golden test for .template.dart for the Dart2JS directory.
  //
  // TODO(matanl): Either fix this case, or find a better way of excluding.
  if (dartFile.endsWith('dart2js_golden.template.dart')) {
    return;
  }

  final checkPath = p.setExtension(dartFile, checkExtension);
  final goldenPath = p.setExtension(dartFile, goldenExtension);
  var check = File(checkPath).readAsStringSync();
  var golden = File(goldenPath).readAsStringSync();
  if (formatDart) {
    check = _dartfmt.format(check);
    golden = _dartfmt.format(golden);
  }
  expect(check, golden, reason: '$goldenPath is out of date. See $checkPath.');
}
