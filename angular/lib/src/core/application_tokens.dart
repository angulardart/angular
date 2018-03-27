import 'di.dart' show MultiToken, OpaqueToken;

/// A dependency injection token representing a unique ID for the application.
///
/// The identifier is used internally to apply CSS scoping behavior.
///
/// To avoid a randomly generated value, a custom value can be provided:
/// ```dart
///   bootstrapStatic(
///     YourAppComponent,
///     const [
///       const Provider(APP_ID, useValue: 'my-unique-id'),
///     ],
///   )
/// ```
const APP_ID = const OpaqueToken<String>('APP_ID');

/// Functions that will be executed when an application is initialized.
@Deprecated('Run functions in the root component instead')
const APP_INITIALIZER = const MultiToken<Function>('NG_APP_INIT');
