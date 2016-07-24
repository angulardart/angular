import "package:angular2/src/core/di.dart" show Injectable;
import "package:angular2/src/core/metadata/directives.dart"
    show ComponentMetadata;
import "package:angular2/src/core/metadata/view.dart" show ViewMetadata;
import "package:angular2/src/core/reflection/reflection.dart" show reflector;
import "package:angular2/src/core/reflection/reflector_reader.dart"
    show ReflectorReader;
import "package:angular2/src/facade/collection.dart" show Map;
import "package:angular2/src/facade/exceptions.dart" show BaseException;
import "package:angular2/src/facade/lang.dart"
    show stringify, isBlank, isPresent;

/**
 * Resolves types to [ViewMetadata].
 */
@Injectable()
class ViewResolver {
  ReflectorReader _reflector;
  /** @internal */
  var _cache = new Map<Type, ViewMetadata>();
  ViewResolver([ReflectorReader _reflector]) {
    if (isPresent(_reflector)) {
      this._reflector = _reflector;
    } else {
      this._reflector = reflector;
    }
  }
  ViewMetadata resolve(Type component) {
    var view = this._cache[component];
    if (isBlank(view)) {
      view = this._resolve(component);
      this._cache[component] = view;
    }
    return view;
  }

  /** @internal */
  ViewMetadata _resolve(Type component) {
    ComponentMetadata compMeta;
    ViewMetadata viewMeta;
    this._reflector.annotations(component).forEach((m) {
      if (m is ViewMetadata) {
        viewMeta = m;
      }
      if (m is ComponentMetadata) {
        compMeta = m;
      }
    });
    if (isPresent(compMeta)) {
      if (isBlank(compMeta.template) &&
          isBlank(compMeta.templateUrl) &&
          isBlank(viewMeta)) {
        throw new BaseException(
            '''Component \'${ stringify ( component )}\' must have either \'template\' or \'templateUrl\' set.''');
      } else if (isPresent(compMeta.template) && isPresent(viewMeta)) {
        this._throwMixingViewAndComponent("template", component);
      } else if (isPresent(compMeta.templateUrl) && isPresent(viewMeta)) {
        this._throwMixingViewAndComponent("templateUrl", component);
      } else if (isPresent(compMeta.directives) && isPresent(viewMeta)) {
        this._throwMixingViewAndComponent("directives", component);
      } else if (isPresent(compMeta.pipes) && isPresent(viewMeta)) {
        this._throwMixingViewAndComponent("pipes", component);
      } else if (isPresent(compMeta.encapsulation) && isPresent(viewMeta)) {
        this._throwMixingViewAndComponent("encapsulation", component);
      } else if (isPresent(compMeta.styles) && isPresent(viewMeta)) {
        this._throwMixingViewAndComponent("styles", component);
      } else if (isPresent(compMeta.styleUrls) && isPresent(viewMeta)) {
        this._throwMixingViewAndComponent("styleUrls", component);
      } else if (isPresent(viewMeta)) {
        return viewMeta;
      } else {
        return new ViewMetadata(
            templateUrl: compMeta.templateUrl,
            template: compMeta.template,
            directives: compMeta.directives,
            pipes: compMeta.pipes,
            encapsulation: compMeta.encapsulation,
            styles: compMeta.styles,
            styleUrls: compMeta.styleUrls);
      }
    } else {
      if (isBlank(viewMeta)) {
        throw new BaseException(
            '''Could not compile \'${ stringify ( component )}\' because it is not a component.''');
      } else {
        return viewMeta;
      }
    }
    return null;
  }

  /** @internal */
  void _throwMixingViewAndComponent(String propertyName, Type component) {
    throw new BaseException(
        '''Component \'${ stringify ( component )}\' cannot have both \'${ propertyName}\' and \'@View\' set at the same time"''');
  }
}
