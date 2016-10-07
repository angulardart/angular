import 'metadata.dart';

export 'metadata.dart';

/// See [InjectMetadata].
class Inject extends InjectMetadata {
  const Inject(dynamic token) : super(token);
}

/// See [OptionalMetadata].
class Optional extends OptionalMetadata {
  const Optional() : super();
}

/// Compile-time metadata that marks a class [Type] or [Function] for injection.
///
/// The `@Injectable()` annotation has two valid uses:
///
/// 1. On a class [Type]
/// 2. On a top-level [Function]
///
/// ## Use #1: A class [Type]
/// The class must be one of the following:
///
///  - non-abstract with a public or default constructor
///  - abstract but with a factory constructor
///
/// A class annotated with `@Injectable()` can have only a single constructor
/// or the default constructor. The DI framework resolves the dependencies
/// and invokes the constructor with the resolved values.
///
/// ### Example
///
/// ```dart
/// // Use the default constructor to create a new instance of MyService.
/// @Injectable()
/// class MyService {}
///
/// // Use the defined constructor to create a new instance of MyService.
/// //
/// // Each positional argument is treated as a dependency to be resolved.
/// @Injectable()
/// class MyService {
///   MyService(Dependency1 d1, Dependency2 d2)
/// }
///
/// // Use the factory constructor to create a new instance of MyServiceImpl.
/// @Injectable()
/// abstract class MyService {
///   factory MyService() => new MyServiceImpl();
/// }
/// ```
///
/// ## Use #2: A top-level [Function]
///
/// The `Injectable()` annotation works with top-level functions
/// when used with `useFactory`.
///
/// ### Example
///
/// ```dart
/// // Could be put anywhere DI providers are allowed.
/// const Provide(MyService, useFactory: createMyService);
///
/// // A `Provide` may now use `createMyService` via `useFactory`.
/// @Injectable()
/// MyService createMyService(Dependency1 d1, Dependency2 d2) => ...
/// ```
class Injectable extends InjectableMetadata {
  const Injectable() : super();
}

/// See [SelfMetadata].
class Self extends SelfMetadata {
  const Self() : super();
}

/// See [HostMetadata].
class Host extends HostMetadata {
  const Host() : super();
}

/// See [SkipSelfMetadata].
class SkipSelf extends SkipSelfMetadata {
  const SkipSelf() : super();
}
