import "package:angular2/src/core/di.dart" show Injectable;
import "package:angular2/src/core/metadata.dart" show Component;
import "package:angular2/src/core/metadata.dart" show View;
import "package:angular2/src/core/reflection/reflection.dart" show reflector;
import "package:angular2/src/core/reflection/reflector_reader.dart"
    show ReflectorReader;
import "package:angular2/src/facade/exceptions.dart" show BaseException;
import "package:angular2/src/facade/lang.dart" show stringify;

/// Resolves types to [View].
@Injectable()
class ViewResolver {
  ReflectorReader _reflector;
  /** @internal */
  var _cache = new Map<Type, View>();
  ViewResolver([ReflectorReader _reflector]) {
    if (_reflector != null) {
      this._reflector = _reflector;
    } else {
      this._reflector = reflector;
    }
  }
  View resolve(Type component) {
    var view = this._cache[component];
    if (view == null) {
      view = this._resolve(component);
      this._cache[component] = view;
    }
    return view;
  }

  /** @internal */
  View _resolve(Type component) {
    Component compMeta;
    View viewMeta;
    this._reflector.annotations(component).forEach((m) {
      if (m is View) {
        viewMeta = m;
      }
      if (m is Component) {
        compMeta = m;
      }
    });
    if (compMeta != null) {
      if (compMeta.template == null &&
          compMeta.templateUrl == null &&
          viewMeta == null) {
        throw new BaseException(
            '''Component \'${ stringify ( component )}\' must have either \'template\' or \'templateUrl\' set.''');
      } else if (compMeta.template != null && viewMeta != null) {
        this._throwMixingViewAndComponent("template", component);
      } else if (compMeta.templateUrl != null && viewMeta != null) {
        this._throwMixingViewAndComponent("templateUrl", component);
      } else if (compMeta.directives != null && viewMeta != null) {
        this._throwMixingViewAndComponent("directives", component);
      } else if (compMeta.pipes != null && viewMeta != null) {
        this._throwMixingViewAndComponent("pipes", component);
      } else if (compMeta.encapsulation != null && viewMeta != null) {
        this._throwMixingViewAndComponent("encapsulation", component);
      } else if (compMeta.styles != null && viewMeta != null) {
        this._throwMixingViewAndComponent("styles", component);
      } else if (compMeta.styleUrls != null && viewMeta != null) {
        this._throwMixingViewAndComponent("styleUrls", component);
      } else if (viewMeta != null) {
        return viewMeta;
      } else {
        return new View(
            templateUrl: compMeta.templateUrl,
            template: compMeta.template,
            directives: compMeta.directives,
            pipes: compMeta.pipes,
            encapsulation: compMeta.encapsulation,
            styles: compMeta.styles,
            styleUrls: compMeta.styleUrls);
      }
    } else {
      if (viewMeta == null) {
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
