// http://go/migrate-deps-first
// @dart=2.9
import 'package:meta/meta.dart';

/// [outputUrl] and the generated [sourceCode] related to view compilation.
class DartSourceOutput {
  final String outputUrl;
  final String sourceCode;

  DartSourceOutput({
    @required this.outputUrl,
    @required this.sourceCode,
  });
}
