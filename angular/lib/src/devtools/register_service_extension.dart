import 'dart:async';
import 'dart:convert' show json;
import 'dart:developer';

import 'package:angular/src/utilities.dart';

import '../core/app.dart';

/// Registers a service extension [handler] that manages a group of objects.
///
/// The [handler] takes a single parameter, `groupName`, that specifies the
/// group used to manage the life cycle of any object references returned in the
/// response. Any object references created for a group will be retained until
/// that group is explicitly disposed.
///
/// The service extension is registered as "ext.angular.[name]".
void registerObjectGroupServiceExtension(
  String name,
  FutureOr<Object?> Function(String groupName) handler,
) {
  _registerServiceExtension(name, (parameters) {
    return handler(parameters['groupName']!);
  });
}

/// Registers a service extension [handler] as "ext.angular.[name]".
void _registerServiceExtension(
  String name,
  FutureOr<Object?> Function(Map<String, String> args) handler,
) {
  final method = 'ext.angular.$name';
  registerExtension(method, (_, args) {
    final completer = Completer<String>();

    // Wait until the app is stable to invoke the handler. This ensures that
    // any state collected by the handler is coherent with the latest change
    // detection pass. Note this does not trigger another change detection
    // pass because it's called from outside the Angular zone.
    App.instance.zone.runAfterChangesObserved(() async {
      try {
        final result = await handler(args);
        final encoded = json.encode({'result': result});
        completer.complete(encoded);
      } catch (exception, stackTrace) {
        completer.completeError(exception, stackTrace);
      }
    });

    return completer.future.then((result) {
      return ServiceExtensionResponse.result(result);
    }, onError: (exception, stackTrace) {
      // TODO(b/158612293): determine if this should be kept.
      App.instance.exceptionHandler.call(unsafeCast(exception), stackTrace);
      return ServiceExtensionResponse.error(
        ServiceExtensionResponse.extensionError,
        json.encode({
          'exception': exception.toString(),
          'stackTrace': stackTrace.toString(),
        }),
      );
    });
  });
}
