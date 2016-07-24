import "package:angular2/src/compiler/view_resolver.dart" show ViewResolver;
import "package:angular2/src/core/di.dart" show Injectable;
import "package:angular2/src/facade/exceptions.dart" show BaseException;

import "../core/metadata.dart" show ViewMetadata;

@Injectable()
class MockViewResolver extends ViewResolver {
  var _views = new Map<Type, ViewMetadata>();
  var _inlineTemplates = new Map<Type, String>();
  var _viewCache = new Map<Type, ViewMetadata>();
  var _directiveOverrides = new Map<Type, Map<Type, Type>>();

  MockViewResolver();

  /// Overrides the [ViewMetadata] for a component.
  void setView(Type component, ViewMetadata view) {
    this._checkOverrideable(component);
    this._views[component] = view;
  }

  /// Overrides the inline template for a component - other configuration
  /// remains unchanged.
  void setInlineTemplate(Type component, String template) {
    this._checkOverrideable(component);
    this._inlineTemplates[component] = template;
  }

  /// Overrides a directive from the component [ViewMetadata].
  void overrideViewDirective(Type component, Type from, Type to) {
    this._checkOverrideable(component);
    var overrides = this._directiveOverrides[component];
    if (overrides == null) {
      overrides = new Map<Type, Type>();
      this._directiveOverrides[component] = overrides;
    }
    overrides[from] = to;
  }

  /// Returns the [ViewMetadata] for a component.
  ///
  /// Set the [ViewMetadata] to the overridden view when it exists or fallback
  /// to the default [ViewResolver],
  ///   see [setView].
  /// - Override the directives, see `overrideViewDirective`.
  /// - Override the @View definition, see `setInlineTemplate`.
  ///
  ViewMetadata resolve(Type component) {
    var view = _viewCache[component];
    if (view != null) return view;
    view = _views[component] ?? super.resolve(component);
    var directives = view.directives;
    var overrides = this._directiveOverrides[component];
    if (overrides != null && directives != null) {
      directives = new List.from(view.directives);
      overrides.forEach((from, to) {
        var srcIndex = directives.indexOf(from);
        if (srcIndex == -1) {
          throw new BaseException(
              'Overriden directive $from not found in the template '
              'of $component');
        }
        directives[srcIndex] = to;
      });
      view = new ViewMetadata(
          template: view.template,
          templateUrl: view.templateUrl,
          directives: directives);
    }
    var inlineTemplate = this._inlineTemplates[component];
    if (inlineTemplate != null) {
      view = new ViewMetadata(
          template: inlineTemplate,
          templateUrl: null,
          directives: view.directives);
    }
    _viewCache[component] = view;
    return view;
  }

  /// Once a component has been compiled, the AppProtoView is stored in the
  /// compiler cache.
  ///
  /// Then it should not be possible to override the component configuration
  /// after the component has been compiled.
  void _checkOverrideable(Type component) {
    if (_viewCache[component] != null) {
      throw new BaseException('The component $component has already '
          'been compiled, its configuration can not be changed');
    }
  }
}
