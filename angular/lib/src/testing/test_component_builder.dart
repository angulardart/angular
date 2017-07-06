import "dart:async";
import "dart:html";

import "package:angular/core.dart"
    show
        ComponentRef,
        DynamicComponentLoader,
        Injector,
        ElementRef,
        ChangeDetectorRef;
import "package:angular/di.dart" show Injectable;
import 'package:angular/platform/common_dom.dart';
import "package:angular/src/core/linker/app_view_utils.dart";
import "package:angular/src/debug/debug_node.dart"
    show DebugElement, getDebugNode;
import "package:angular/src/platform/dom/dom_tokens.dart" show DOCUMENT;
import 'package:angular/src/platform/dom/shared_styles_host.dart';

/// Fixture for debugging and testing a component.
class ComponentFixture {
  /// The DebugElement associated with the root element of this component.
  DebugElement _debugElement;

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
    _debugElement = (getDebugNode(elementRef.nativeElement) as DebugElement);
    componentInstance = ref.instance;
    assert(componentInstance != null);
    nativeElement = elementRef.nativeElement;
    componentRef = ref;
  }

  DebugElement get debugElement {
    if (_debugElement == null) {
      throw new Exception(
          'DebugElement is not available in DART_CODEGEN_MODE=release');
    }
    return _debugElement;
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

  TestComponentBuilder(this._injector) {
    // Required because reflective tests do not create a PlatformRef.
    sharedStylesHost ??= new DomSharedStylesHost(document);
  }

  TestComponentBuilder _clone() {
    var clone = new TestComponentBuilder(_injector);
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
    return clone;
  }

  /// Builds and returns a ComponentFixture.
  Future<ComponentFixture> createAsync(Type rootComponentType) {
    AppViewUtils.resetChangeDetection();
    var rootElId = '''root${ _nextRootElementId ++}''';
    var rootEl = new DivElement()..id = rootElId;
    var doc = _injector.get(DOCUMENT);
    // TODO(juliemr): can/should this be optional?
    var oldRoots = doc.querySelectorAll("[id^=root]");
    for (var i = 0; i < oldRoots.length; i++) {
      oldRoots[i].remove();
    }
    (doc as HtmlDocument).body.append(rootEl);
    DynamicComponentLoader loader = _injector.get(DynamicComponentLoader);
    appViewUtils = _injector.get(AppViewUtils);
    Future<ComponentRef> promise = loader.load(rootComponentType, _injector);
    return promise.then((componentRef) {
      querySelector('#$rootElId')
          .append(componentRef.location.nativeElement as Element);
      return new ComponentFixture(componentRef);
    });
  }
}
