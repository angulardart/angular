/// Marks a function or method as an Angular 2 entrypoint.
///
/// The optional [name] parameter will be reflected in logs when the entry point
/// is processed.
///
/// See [the wiki][] for detailed documentation.
/// [the wiki]: https://github.com/dart-lang/angular2/wiki/Transformer#entry_points
///
/// ## Example
///
/// ```
/// @AngularEntrypoint('name-for-debug')
/// void main() {
///   bootstrap(MyComponent);
/// }
/// ```
class AngularEntrypoint {
  final String name;
  const AngularEntrypoint([this.name]);
}
