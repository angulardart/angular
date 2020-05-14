import 'package:meta/meta.dart';

/// [outputUrl] and the generated [sourceCode] related to view compilation.
class DartSourceOutput {
  final String outputUrl;
  final String sourceCode;

  /// Module URLs that should be deferred when finalizing the output.
  ///
  /// The _key_ is the URL and the _value_ is the _prefix_ that should be used
  /// when referring to that unit of code. For example:
  /// ```
  /// {
  ///   'asset/path.template.dart': 'deferred_import_1',
  /// }
  /// ```
  final Map<String, String> deferredModules;

  DartSourceOutput({
    @required this.outputUrl,
    @required this.sourceCode,
    this.deferredModules = const {},
  });
}
