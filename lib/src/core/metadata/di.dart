export "package:angular2/src/core/di/decorators.dart";

/// Defines an injectable whose value is given by a property on an
/// InjectorModule class.
///
/// ## Example
///
/// ```dart
/// @InjectorModule()
/// class MyModule {
///   @ProviderProperty(SomeToken)
///   String someProp = 'Hello World';
/// }
/// ```
/// @experimental
class ProviderProperty {
  final dynamic token;
  final bool _multi;
  const ProviderProperty(this.token, {bool multi: false}) : _multi = multi;
  bool get multi {
    return this._multi;
  }
}
