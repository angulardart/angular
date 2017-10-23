import 'di.dart' show OpaqueToken;

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
const OpaqueToken APP_ID = const OpaqueToken('APP_ID');

/// A function that will be executed when a platform is initialized.
const OpaqueToken PLATFORM_INITIALIZER =
    const OpaqueToken("Platform Initializer");

/// A function that will be executed when an application is initialized.
const OpaqueToken APP_INITIALIZER =
    const OpaqueToken("Application Initializer");
