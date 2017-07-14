import "package:angular/src/core/di.dart" show Injectable;
import "package:angular/src/core/metadata.dart";

/// Resolve a [Type] for [Directive].
///
/// This interface can be overridden by the application developer
/// to create custom behavior.
///
/// See [Compiler]
///
@Injectable()
class DirectiveResolver {
  const DirectiveResolver();

  /// Return [Directive] for a given `Type`.
  Directive resolve(Type type) => throw new UnsupportedError('');
}
