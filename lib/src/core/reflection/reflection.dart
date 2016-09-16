import 'package:angular2/src/facade/lang.dart';

import 'platform_reflection_capabilities.dart';
import 'reflector.dart';
import 'types.dart';

export 'reflector.dart';

class NoReflectionCapabilities implements PlatformReflectionCapabilities {
  @override
  bool isReflectionEnabled() {
    return false;
  }

  @override
  Function factory(Type type) =>
      throw new NoReflectionCapabilitiesError._noInfo(type);
  @override
  List interfaces(Type type) =>
      throw new NoReflectionCapabilitiesError._noInfo(type);
  @override
  List<List> parameters(dynamic type) =>
      throw new NoReflectionCapabilitiesError._noInfo(type);

  @override
  List annotations(dynamic type) => throw new NoReflectionCapabilitiesError._(
      "Cannot find reflection information on ${stringify(type)}");

  @override
  Map<String, List> propMetadata(dynamic type) =>
      throw new NoReflectionCapabilitiesError._noInfo(type);
  @override
  GetterFn getter(String name) =>
      throw new NoReflectionCapabilitiesError._("Cannot find getter ${name}");

  @override
  SetterFn setter(String name) =>
      throw new NoReflectionCapabilitiesError._("Cannot find setter ${name}");

  @override
  MethodFn method(String name) =>
      throw new NoReflectionCapabilitiesError._("Cannot find method ${name}");

  @override
  String importUri(Type type) => './';
}

final Reflector reflector = new Reflector(new NoReflectionCapabilities());

class NoReflectionCapabilitiesError extends Error {
  final String message;

  NoReflectionCapabilitiesError._(this.message);

  factory NoReflectionCapabilitiesError._noInfo(dynamic type) =>
      new NoReflectionCapabilitiesError._(
          "Cannot find reflection information on ${stringify(type)}");

  @override
  String toString() => message;
}
