import 'dart:html';

/// Provides a hook for receiving unhandled errors/exceptions.
///
/// The default implementation of `ExceptionHandler` when used in AngularDart
/// prints the error message directly to the JavaScript developer console.
///
/// It's possible to instead write a _custom exception handler_:
/// ```
/// import 'package:angular/angular.dart';
///
/// import 'main.template.dart' as ng;
///
/// class MyExceptionHandler implements ExceptionHandler {
///   @override
///   void call(exception, [stackTrace, String reason]) {
///     // Do something with this exception, like send to an online service.
///   }
/// }
///
/// @GenerateInjector([
///   ClassProvider(ExceptionHandler, useClass: MyExceptionHandler),
/// ])
/// final InjectorFactory appInjector = ng.appInjector$Injector;
///
/// void main() {
///   runApp(
///     ng.createMyAppFactory(),
///     createInjector: appInjector,
///   );
/// }
/// ```
class ExceptionHandler {
  /// Internal use only: Converts a caught angular exception into a string.
  ///
  /// **NOTE**: [stackTrace] _should_ be typed as `StackTrace`, but currently is
  /// not and there is user code depending on this being more generic. Follow
  /// b/162611781.
  static String exceptionToString(
    Object exception, [
    Object? stackTrace,
    @Deprecated('No longer supported. Remove this argument.') String? reason,
  ]) {
    final buffer = StringBuffer();
    buffer.writeln('EXCEPTION: $exception');
    if (stackTrace != null) {
      buffer.writeln('STACKTRACE: ');
      buffer.writeln(stackTrace.toString());
    }
    return buffer.toString();
  }

  const ExceptionHandler();

  /// Handles an error or [exception] caught at runtime.
  ///
  /// **NOTE**: [stackTrace] _should_ be typed as `StackTrace`, but currently is
  /// not and there is user code depending on this being more generic. Follow
  /// b/162611781.
  ///
  /// **NOTE**: [reason] is always null and never provided. See b/162611781.
  void call(
    Object exception, [
    Object? stackTrace,
    @Deprecated('No longer supported. Remove this argument.') String? reason,
  ]) {
    window.console.error(ExceptionHandler.exceptionToString(
      exception,
      stackTrace,
      reason,
    ));
  }
}
