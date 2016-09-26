import 'metadata.dart';

export 'metadata.dart';

/// {@link InjectMetadata}.
class Inject extends InjectMetadata {
  const Inject(dynamic token) : super(token);
}

/// {@link OptionalMetadata}.
class Optional extends OptionalMetadata {
  const Optional() : super();
}

/// Compile-time metadata that marks a class [Type] or [Function] for injection.
///
/// `@Injectable()` has two valid uses:
///
/// 1. On a class [Type] where:
/// - the class is non-abstract with a public or default constructor
/// - the class is abstract but has a factory constructor
///
/// __Example use__:
///   // Use the default constructor to create a new instance of MyService
///   @Injectable()
///   class MyService {}
///
///   // Use the defined constructor to create a new instance of MyService
///   //
///   // Each positional argument is treated as a dependency to be resolved.
///   @Injectable()
///   class MyService {
///     MyService(Dependency1 d1, Dependency2 d2)
///   }
///
///   // Use the factory constructor to create a new instance of MyServiceImpl.
///   @Injectable()
///   abstract class MyService {
///     factory MyService() => new MyServiceImpl();
///   }
///
/// 2. On a top-level [Function] when used in conjunction with `useFactory`.
///
/// __Example use__:
///   // Could be put anywhere DI providers are allowed.
///   const Provide(MyService, useFactory: createMyService);
///
///   // A `Provide` may now use `createMyService` via `useFactory`.
///   @Injectable()
///   MyService createMyService(Dependency1 d1, Dependency2 d2) => ...
class Injectable extends InjectableMetadata {
  const Injectable() : super();
}

/// {@link SelfMetadata}.
class Self extends SelfMetadata {
  const Self() : super();
}

/// {@link HostMetadata}.
class Host extends HostMetadata {
  const Host() : super();
}

/// {@link SkipSelfMetadata}.
class SkipSelf extends SkipSelfMetadata {
  const SkipSelf() : super();
}
