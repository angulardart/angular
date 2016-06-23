library angular2.src.testing.test_component_builder;

import "dart:async";
import "package:angular2/core.dart"
    show
        ComponentRef,
        DynamicComponentLoader,
        Injector,
        Injectable,
        ViewMetadata,
        ElementRef,
        EmbeddedViewRef,
        ChangeDetectorRef,
        provide;
import "package:angular2/compiler.dart" show DirectiveResolver, ViewResolver;
import "package:angular2/src/facade/lang.dart" show Type, isPresent, isBlank;
import "package:angular2/src/facade/async.dart" show PromiseWrapper;
import "package:angular2/src/facade/collection.dart"
    show ListWrapper, MapWrapper;
import "utils.dart" show el;
import "package:angular2/src/platform/dom/dom_tokens.dart" show DOCUMENT;
import "package:angular2/src/platform/dom/dom_adapter.dart" show DOM;
import "package:angular2/src/core/debug/debug_node.dart"
    show DebugNode, DebugElement, getDebugNode;
import "fake_async.dart" show tick;

/**
 * Fixture for debugging and testing a component.
 */
class ComponentFixture {
  /**
   * The DebugElement associated with the root element of this component.
   */
  DebugElement debugElement;
  /**
   * The instance of the root component class.
   */
  dynamic componentInstance;
  /**
   * The native element at the root of the component.
   */
  dynamic nativeElement;
  /**
   * The ElementRef for the element at the root of the component.
   */
  ElementRef elementRef;
  /**
   * The ComponentRef for the component
   */
  ComponentRef componentRef;
  /**
   * The ChangeDetectorRef for the component
   */
  ChangeDetectorRef changeDetectorRef;
  ComponentFixture(ComponentRef componentRef) {
    this.changeDetectorRef = componentRef.changeDetectorRef;
    this.elementRef = componentRef.location;
    this.debugElement =
        (getDebugNode(this.elementRef.nativeElement) as DebugElement);
    this.componentInstance = componentRef.instance;
    this.nativeElement = this.elementRef.nativeElement;
    this.componentRef = componentRef;
  }
  /**
   * Trigger a change detection cycle for the component.
   */
  void detectChanges([bool checkNoChanges = true]) {
    this.changeDetectorRef.detectChanges();
    if (checkNoChanges) {
      this.checkNoChanges();
    }
  }

  void checkNoChanges() {
    this.changeDetectorRef.checkNoChanges();
  }

  /**
   * Trigger component destruction.
   */
  void destroy() {
    this.componentRef.destroy();
  }
}

var _nextRootElementId = 0;

/**
 * Builds a ComponentFixture for use in component level tests.
 */
@Injectable()
class TestComponentBuilder {
  Injector _injector;
  /** @internal */
  var _bindingsOverrides = new Map<Type, List<dynamic>>();
  /** @internal */
  var _directiveOverrides = new Map<Type, Map<Type, Type>>();
  /** @internal */
  var _templateOverrides = new Map<Type, String>();
  /** @internal */
  var _viewBindingsOverrides = new Map<Type, List<dynamic>>();
  /** @internal */
  var _viewOverrides = new Map<Type, ViewMetadata>();
  TestComponentBuilder(this._injector) {}
  /** @internal */
  TestComponentBuilder _clone() {
    var clone = new TestComponentBuilder(this._injector);
    clone._viewOverrides = MapWrapper.clone(this._viewOverrides);
    clone._directiveOverrides = MapWrapper.clone(this._directiveOverrides);
    clone._templateOverrides = MapWrapper.clone(this._templateOverrides);
    clone._bindingsOverrides = MapWrapper.clone(this._bindingsOverrides);
    clone._viewBindingsOverrides =
        MapWrapper.clone(this._viewBindingsOverrides);
    return clone;
  }

  /**
   * Overrides only the html of a [ComponentMetadata].
   * All the other properties of the component's [ViewMetadata] are preserved.
   *
   * 
   * 
   *
   * 
   */
  TestComponentBuilder overrideTemplate(Type componentType, String template) {
    var clone = this._clone();
    clone._templateOverrides[componentType] = template;
    return clone;
  }

  /**
   * Overrides a component's [ViewMetadata].
   *
   * 
   * 
   *
   * 
   */
  TestComponentBuilder overrideView(Type componentType, ViewMetadata view) {
    var clone = this._clone();
    clone._viewOverrides[componentType] = view;
    return clone;
  }

  /**
   * Overrides the directives from the component [ViewMetadata].
   *
   * 
   * 
   * 
   *
   * 
   */
  TestComponentBuilder overrideDirective(
      Type componentType, Type from, Type to) {
    var clone = this._clone();
    var overridesForComponent = clone._directiveOverrides[componentType];
    if (!isPresent(overridesForComponent)) {
      clone._directiveOverrides[componentType] = new Map<Type, Type>();
      overridesForComponent = clone._directiveOverrides[componentType];
    }
    overridesForComponent[from] = to;
    return clone;
  }

  /**
   * Overrides one or more injectables configured via `providers` metadata property of a directive
   * or
   * component.
   * Very useful when certain providers need to be mocked out.
   *
   * The providers specified via this method are appended to the existing `providers` causing the
   * duplicated providers to
   * be overridden.
   *
   * 
   * 
   *
   * 
   */
  TestComponentBuilder overrideProviders(Type type, List<dynamic> providers) {
    var clone = this._clone();
    clone._bindingsOverrides[type] = providers;
    return clone;
  }

  /**
   * 
   */
  TestComponentBuilder overrideBindings(Type type, List<dynamic> providers) {
    return this.overrideProviders(type, providers);
  }

  /**
   * Overrides one or more injectables configured via `providers` metadata property of a directive
   * or
   * component.
   * Very useful when certain providers need to be mocked out.
   *
   * The providers specified via this method are appended to the existing `providers` causing the
   * duplicated providers to
   * be overridden.
   *
   * 
   * 
   *
   * 
   */
  TestComponentBuilder overrideViewProviders(
      Type type, List<dynamic> providers) {
    var clone = this._clone();
    clone._viewBindingsOverrides[type] = providers;
    return clone;
  }

  /**
   * 
   */
  TestComponentBuilder overrideViewBindings(
      Type type, List<dynamic> providers) {
    return this.overrideViewProviders(type, providers);
  }

  /**
   * Builds and returns a ComponentFixture.
   *
   * 
   */
  Future<ComponentFixture> createAsync(Type rootComponentType) {
    var mockDirectiveResolver = this._injector.get(DirectiveResolver);
    var mockViewResolver = this._injector.get(ViewResolver);
    this
        ._viewOverrides
        .forEach((type, view) => mockViewResolver.setView(type, view));
    this._templateOverrides.forEach(
        (type, template) => mockViewResolver.setInlineTemplate(type, template));
    this._directiveOverrides.forEach((component, overrides) {
      overrides.forEach((from, to) {
        mockViewResolver.overrideViewDirective(component, from, to);
      });
    });
    this._bindingsOverrides.forEach((type, bindings) =>
        mockDirectiveResolver.setBindingsOverride(type, bindings));
    this._viewBindingsOverrides.forEach((type, bindings) =>
        mockDirectiveResolver.setViewBindingsOverride(type, bindings));
    var rootElId = '''root${ _nextRootElementId ++}''';
    var rootEl = el('''<div id="${ rootElId}"></div>''');
    var doc = this._injector.get(DOCUMENT);
    // TODO(juliemr): can/should this be optional?
    var oldRoots = DOM.querySelectorAll(doc, "[id^=root]");
    for (var i = 0; i < oldRoots.length; i++) {
      DOM.remove(oldRoots[i]);
    }
    DOM.appendChild(doc.body, rootEl);
    Future<ComponentRef> promise = this
        ._injector
        .get(DynamicComponentLoader)
        .loadAsRoot(rootComponentType, '''#${ rootElId}''', this._injector);
    return promise.then((componentRef) {
      return new ComponentFixture(componentRef);
    });
  }

  ComponentFixture createFakeAsync(Type rootComponentType) {
    var result;
    var error;
    PromiseWrapper.then(this.createAsync(rootComponentType), (_result) {
      result = _result;
    }, (_error) {
      error = _error;
    });
    tick();
    if (isPresent(error)) {
      throw error;
    }
    return result;
  }
}
