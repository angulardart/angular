import 'package:dart_style/dart_style.dart';

AngularDartFormatter _formatter;

void init(DartFormatter formatter) {
  _formatter = new _RealFormatter(formatter);
}

AngularDartFormatter get formatter =>
    _formatter ??= new _PassThroughFormatter();

abstract class AngularDartFormatter {
  String format(String source, {uri});
}

class _PassThroughFormatter implements AngularDartFormatter {
  String format(String source, {uri}) => source;
}

class _RealFormatter implements AngularDartFormatter {
  final DartFormatter _formatter;

  _RealFormatter(this._formatter);

  String format(source, {uri}) => _formatter.format(source, uri: uri);
}
