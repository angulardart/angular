import 'dart:html';

import 'package:angular/core.dart'
    show ComponentRef, Injector, ElementRef, ChangeDetectorRef;
import 'package:angular/di.dart' show Injectable;
import 'package:angular/src/core/render/api.dart' show sharedStylesHost;
import 'package:angular/src/platform/dom/shared_styles_host.dart';

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
}
