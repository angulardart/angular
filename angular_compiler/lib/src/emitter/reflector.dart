import '../analyzer/reflector.dart';

/// Generates `.dart` source code given a [ReflectableOutput].
class ReflectableEmitter {
  static const _package = 'package:angular';

  final String reflectorSource;
  final ReflectableOutput _output;

  const ReflectableEmitter(
    this._output, {
    this.reflectorSource: '$_package/src/core/reflection/reflection.dart',
  });

  bool get _linkingNeeded => _output.urlsNeedingInitReflector.isNotEmpty;

  bool get _registrationNeeded =>
      _output.registerClasses.isNotEmpty ||
      _output.registerFunctions.isNotEmpty;

  bool get _isNoop => !_linkingNeeded && !_registrationNeeded;

  /// Writes `import` statements needed for [emitInitReflector].
  ///
  /// They are all prefixed in a way that should not conflict with others.
  String emitImports() {
    if (_isNoop) {
      return '// No initReflector() linking required.\n';
    }
    final urls = _output.urlsNeedingInitReflector;
    final output = new StringBuffer('// Required for initReflector().\n');
    if (_registrationNeeded) {
      output.writeln("import '$reflectorSource' as _ngRef;");
    }
    if (_linkingNeeded)
      for (var i = 0; i < urls.length; i++) {
        output.writeln("import '${urls[i]}' as _ref$i;");
      }
    return (output..writeln()).toString();
  }

  /// Writes `initReflector`, including a preamble if required.
  String emitInitReflector() {
    if (_isNoop) {
      return '// No initReflector() needed.\nvoid initReflector() {}\n';
    }
    final output = new StringBuffer('void initReflector() {\n');
    if (_linkingNeeded) {
      for (var i = 0; i < _output.urlsNeedingInitReflector.length; i++) {
        output.writeln('  _ref$i.initReflector();');
      }
    }
    if (_registrationNeeded) {
      output.writeln('  // TODO: Register functions and classes.');
    }
    return (output..writeln('}')).toString();
  }
}
