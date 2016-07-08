library angular2.src.compiler.pipe_resolver;

import "package:angular2/src/core/di.dart" show resolveForwardRef, Injectable;
import "package:angular2/src/core/metadata.dart" show PipeMetadata;
import "package:angular2/src/core/reflection/reflection.dart" show reflector;
import "package:angular2/src/core/reflection/reflector_reader.dart"
    show ReflectorReader;
import "package:angular2/src/facade/exceptions.dart" show BaseException;
import "package:angular2/src/facade/lang.dart" show Type, isPresent, stringify;

bool _isPipeMetadata(dynamic type) {
  return type is PipeMetadata;
}

/**
 * Resolve a `Type` for [PipeMetadata].
 *
 * This interface can be overridden by the application developer to create custom behavior.
 *
 * See [Compiler]
 */
@Injectable()
class PipeResolver {
  ReflectorReader _reflector;
  PipeResolver([ReflectorReader _reflector]) {
    if (isPresent(_reflector)) {
      this._reflector = _reflector;
    } else {
      this._reflector = reflector;
    }
  }
  /**
   * Return [PipeMetadata] for a given `Type`.
   */
  PipeMetadata resolve(Type type) {
    var metas = this._reflector.annotations(resolveForwardRef(type));
    if (isPresent(metas)) {
      var annotation = metas.firstWhere(_isPipeMetadata, orElse: () => null);
      if (isPresent(annotation)) {
        return annotation;
      }
    }
    throw new BaseException(
        '''No Pipe decorator found on ${ stringify ( type )}''');
  }
}
