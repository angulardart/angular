import "dart:async";

import "package:angular2/compiler.dart" show DirectiveResolver, ViewResolver;
import "package:angular2/core.dart"
    show
        ComponentRef,
        DynamicComponentLoader,
        Injector,
        Injectable,
        View,
        ElementRef,
        ChangeDetectorRef;
import "package:angular2/src/core/linker/app_view_utils.dart";
import "package:angular2/src/debug/debug_node.dart"
    show DebugElement, getDebugNode;
import "package:angular2/src/platform/dom/dom_adapter.dart" show DOM;
import "package:angular2/src/platform/dom/dom_tokens.dart" show DOCUMENT;

import "fake_async.dart" show tick;
import "utils.dart" show el;

/// Fixture for debugging and testing a component.
class ComponentFixture {
  /// The DebugElement associated with the root element of this component.
  DebugElement debugElement;

  /// The instance of the root component class.
  dynamic componentInstance;

  /// The native element at the root of the component.
  dynamic nativeElement;

  /// The [ElementRef] for the element at the root of the component.
  ElementRef elementRef;

  /// The [ComponentRef] for the component.
  ComponentRef componentRef;

  /// The [ChangeDetectorRef] for the component.
  ChangeDetectorRef changeDetectorRef;

  ComponentFixture(ComponentRef ref) {
    changeDetectorRef = ref.changeDetectorRef;
    elementRef = ref.location;
    debugElement = (getDebugNode(elementRef.nativeElement) as DebugElement);
    assert(debugElement != null);
    componentInstance = ref.instance;
    assert(componentInstance != null);
    nativeElement = elementRef.nativeElement;
    componentRef = ref;
  }

  /// Trigger a change detection cycle for the component.
  void detectChanges([bool checkForNoChanges = true]) {
    AppViewUtils.resetChangeDetection();
    changeDetectorRef.detectChanges();
    if (checkForNoChanges) {
      checkNoChanges();
    }
  }

  void checkNoChanges() {
    changeDetectorRef.checkNoChanges();
  }

  /// Trigger component destruction.
  void destroy() {
    componentRef.destroy();
  }
}

var _nextRootElementId = 0;

/// Builds a ComponentFixture for use in component level tests.
@Injectable()
class TestComponentBuilder {
  Injector _injector;

  var _bindingsOverrides = new Map<Type, List<dynamic>>();
  var _directiveOverrides = new Map<Type, Map<Type, Type>>();
  var _templateOverrides = new Map<Type, String>();
  var _viewBindingsOverrides = new Map<Type, List<dynamic>>();
  var _viewOverrides = new Map<Type, View>();

  TestComponentBuilder(this._injector);
  TestComponentBuilder _clone() {
    var clone = new TestComponentBuilder(_injector);
    clone._viewOverrides = new Map.from(_viewOverrides);
    clone._directiveOverrides = new Map.from(_directiveOverrides);
    clone._templateOverrides = new Map.from(_templateOverrides);
    clone._bindingsOverrides = new Map.from(_bindingsOverrides);
    clone._viewBindingsOverrides = new Map.from(_viewBindingsOverrides);
    return clone;
  }

  /// Overrides only the html of a [Component].
  ///
  /// All the other properties of the component's [View] are preserved.
  TestComponentBuilder overrideTemplate(Type componentType, String template) {
    var clone = _clone();
    clone._templateOverrides[componentType] = template;
    return clone;
  }

  /// Overrides a component's [View].
  TestComponentBuilder overrideView(Type componentType, View view) {
    var clone = _clone();
    clone._viewOverrides[componentType] = view;
    return clone;
  }

  /// Overrides the directives from the component [View].
  TestComponentBuilder overrideDirective(
      Type componentType, Type from, Type to) {
    var clone = _clone();
    var overridesForComponent = clone._directiveOverrides[componentType];
    if (overridesForComponent == null) {
      clone._directiveOverrides[componentType] = new Map<Type, Type>();
      overridesForComponent = clone._directiveOverrides[componentType];
    }
    overridesForComponent[from] = to;
    return clone;
  }

  /// Overrides one or more injectables configured via [providers] metadata
  /// property of a directive or component.
  ///
  /// Very useful when certain providers need to be mocked out.
  ///
  /// The providers specified via this method are appended to the existing
  /// [providers] causing the duplicated providers to be overridden.
  TestComponentBuilder overrideProviders(Type type, List<dynamic> providers) {
    var clone = _clone();
    clone._bindingsOverrides[type] = providers;
    return clone;
  }

  TestComponentBuilder overrideBindings(Type type, List<dynamic> providers) {
    return overrideProviders(type, providers);
  }

  /// Overrides one or more injectables configured via [providers] metadata
  /// property of a directive or component.
  ///
  /// Very useful when certain providers need to be mocked out.
  ///
  /// The providers specified via this method are appended to the existing
  /// [providers] causing the duplicated providers to be overridden.
  TestComponentBuilder overrideViewProviders(
      Type type, List<dynamic> providers) {
    var clone = _clone();
    clone._viewBindingsOverrides[type] = providers;
    return clone;
  }

  TestComponentBuilder overrideViewBindings(
      Type type, List<dynamic> providers) {
    return overrideViewProviders(type, providers);
  }

  /// Builds and returns a ComponentFixture.
  Future<ComponentFixture> createAsync(Type rootComponentType) {
    AppViewUtils.resetChangeDetection();
    var mockDirectiveResolver = _injector.get(DirectiveResolver);
    var mockViewResolver = _injector.get(ViewResolver);
    _viewOverrides
        .forEach((type, view) => mockViewResolver.setView(type, view));
    _templateOverrides.forEach(
        (type, template) => mockViewResolver.setInlineTemplate(type, template));
    _directiveOverrides.forEach((component, overrides) {
      overrides.forEach((from, to) {
        mockViewResolver.overrideViewDirective(component, from, to);
      });
    });
    _bindingsOverrides.forEach((type, bindings) =>
        mockDirectiveResolver.setBindingsOverride(type, bindings));
    _viewBindingsOverrides.forEach((type, bindings) =>
        mockDirectiveResolver.setViewBindingsOverride(type, bindings));
    var rootElId = '''root${ _nextRootElementId ++}''';
    var rootEl = el('''<div id="${ rootElId}"></div>''');
    var doc = _injector.get(DOCUMENT);
    // TODO(juliemr): can/should this be optional?
    var oldRoots = DOM.querySelectorAll(doc, "[id^=root]");
    for (var i = 0; i < oldRoots.length; i++) {
      DOM.remove(oldRoots[i]);
    }
    DOM.appendChild(doc.body, rootEl);
    DynamicComponentLoader loader = _injector.get(DynamicComponentLoader);
    appViewUtils = _injector.get(AppViewUtils);
    Future<ComponentRef> promise = loader.loadAsRoot(
        rootComponentType, _injector,
        overrideSelector: '#${rootElId}');
    return promise.then((componentRef) {
      return new ComponentFixture(componentRef);
    });
  }

  ComponentFixture createFakeAsync(Type rootComponentType) {
    var result;
    var error;
    createAsync(rootComponentType).then((_result) {
      result = _result;
    }, onError: (_error) {
      error = _error;
    });
    tick();
    if (error != null) throw error;
    return result;
  }
}
