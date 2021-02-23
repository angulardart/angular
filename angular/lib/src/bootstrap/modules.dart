import 'dart:math';

import 'package:angular/src/core/application_tokens.dart';
import 'package:angular/src/core/exception_handler.dart';
import 'package:angular/src/core/linker/component_loader.dart';
import 'package:angular/src/di/injector.dart';

/// Returns a simple application [Injector] that is hand-authored.
///
/// Some of the services provided below ([ExceptionHandler], [APP_ID]) may be
/// overriden by the user-supplied injector - the returned [InjectorFactory] is
/// used as the "base" application injector.
///
/// Previously this used `@GenerateInjector`, but that requires running the
/// Angular generator _on_ Angular itself, which leads to tricky circular
/// dependency issues for little value.
InjectorFactory minimalApp() {
  return (parent) {
    return Injector.map({
      APP_ID: _createRandomAppId(),
      ExceptionHandler: const ExceptionHandler(),
      ComponentLoader: const ComponentLoader(),
    }, parent);
  };
}

/// Creates a random [APP_ID] for use in CSS encapsulation.
String _createRandomAppId() {
  final random = Random();
  String char() => String.fromCharCode(97 + random.nextInt(26));
  return '${char()}${char()}${char()}';
}
