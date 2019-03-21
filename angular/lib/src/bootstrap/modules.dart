/// Contains the internal dependency injection "modules" required for bootstrap.
library angular.src.bootstrap.modules;

import 'dart:math';

import 'package:angular/src/core/application_tokens.dart';
import 'package:angular/src/core/di.dart';
import 'package:angular/src/core/linker/component_loader.dart';
import 'package:angular/src/core/linker/dynamic_component_loader.dart';
import 'package:angular/src/core/zone.dart';
import 'package:angular/src/di/providers.dart';
import 'package:angular/src/facade/exception_handler.dart';
import 'package:angular/src/platform/browser/exceptions.dart';
import 'package:angular/src/platform/dom/events/dom_events.dart';
import 'package:angular/src/platform/dom/events/event_manager.dart';
import 'package:angular/src/platform/dom/events/key_events.dart';
import 'package:angular/src/runtime.dart';
import 'package:angular/src/security/dom_sanitization_service.dart';
import 'package:angular/src/security/dom_sanitization_service_impl.dart';

import 'modules.template.dart' as ng;

/// Creates a list of [EventManagerPlugins] to be used by [EventManager].
List<EventManagerPlugin> createEventPlugins() {
  // Order here is very important, it is reversed before being registered, and
  // DomEventsPlugin is a catch-all so it *must* happen last.
  return [
    DomEventsPlugin(),
    KeyEventsPlugin(),
  ];
}

/// Implementation of [SlowComponentLoader] that throws [UnsupportedError].
///
/// This is to allow a migration path for common components that may need to
/// inject [SlowComponentLoader] for the legacy `bootstrapStatic` method, but
/// won't actually use it in apps that called `bootstrapFactory`.
class ThrowingSlowComponentLoader implements SlowComponentLoader {
  static const _slowComponentLoaderWarning =
      'You are using runApp or runAppAsync, which does not support loading a '
      'component with SlowComponentLoader. Please migrate this code to use '
      'ComponentLoader instead.';

  const ThrowingSlowComponentLoader();

  @override
  load<T>(_, __) {
    throw UnsupportedError(_slowComponentLoaderWarning);
  }

  @override
  loadNextToLocation<T>(_, __, [___]) {
    throw UnsupportedError(_slowComponentLoaderWarning);
  }
}

/// Strict subset module of AngularDart functionality.
///
/// Does not support any service that requires the `initReflector()`-based APIs.
const bootstrapMinimalModule = <Object>[
  // HTML/DOM sanitization.
  ClassProvider(ExceptionHandler, useClass: BrowserExceptionHandler),
  ExistingProvider(SanitizationService, DomSanitizationService),
  ClassProvider(DomSanitizationService, useClass: DomSanitizationServiceImpl),

  // Core components of the runtime.
  FactoryProvider.forToken(APP_ID, createRandomAppId),
  ClassProvider(ComponentLoader),
  ClassProvider(SlowComponentLoader, useClass: ThrowingSlowComponentLoader),
];

/// An application [Injector] that is statically generated.
///
/// TODO(b/129076213): Remove this.
@GenerateInjector([bootstrapMinimalModule])
final InjectorFactory minimalApp = ng.minimalApp$Injector;

/// Creates an AngularDart zone, enabling async stack traces in developer mode.
NgZone createNgZone() => NgZone(enableLongStackTrace: isDevMode);

/// Creates a random [APP_ID] for use in CSS encapsulation.
String createRandomAppId() {
  final random = Random();
  String char() => String.fromCharCode(97 + random.nextInt(26));
  return '${char()}${char()}${char()}';
}
