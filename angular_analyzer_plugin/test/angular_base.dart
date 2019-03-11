import 'analyzer_base.dart';

class AngularTestBase extends AnalyzerTestBase {
  @override
  void setUp() {
    super.setUp();
    _addAngularSources();
  }

  void _addAngularSources() {
    newSource('/angular/angular.dart', r'''
library angular;

export 'src/core/metadata.dart';
export 'src/core/ng_if.dart';
export 'src/core/ng_for.dart';
export 'src/core/change_detection.dart';
''');
    newSource('/angular/security.dart', r'''
library angular.security;
export 'src/security/dom_sanitization_service.dart';
''');
    newSource('/angular/src/core/metadata.dart', r'''
import 'dart:async';

abstract class Directive {
  const Directive(
      {String selector,
      Map<String, String> host,
      @Deprecated('Use `providers` instead') List bindings,
      List providers,
      String exportAs,
      String moduleId,
      Map<String, dynamic> queries})
      : super(
            selector: selector,
            properties: properties,
            events: events,
            host: host,
            bindings: bindings,
            providers: providers,
            exportAs: exportAs,
            moduleId: moduleId,
            queries: queries);
}

class Component extends Directive {
  final List<Object> directives;
  const Component(
      {String selector,
      Map<String, String> host,
      @Deprecated('Use `providers` instead') List bindings,
      List providers,
      String exportAs,
      String moduleId,
      Map<String, dynamic> queries,
      @Deprecated('Use `viewProviders` instead') List viewBindings,
      List viewProviders,
      ChangeDetectionStrategy changeDetection,
      String templateUrl,
      String template,
      this.directives,
      dynamic pipes,
      ViewEncapsulation encapsulation,
      List exports,
      List<String> styles,
      List<String> styleUrls});
}

class Pipe {
  final String name;
  final bool _pure;
  const Pipe(this.name, {bool pure});
}

class Input {
  final String bindingPropertyName;
  const Input([this.bindingPropertyName]);
}

class Output {
  final String bindingPropertyName;
  const Output([this.bindingPropertyName]);
}

class Attribute {
  final String attributeName;
  const Attribute(this.attributeName);
}

class ContentChild extends Query {
  const ContentChild(dynamic /* Type | String */ selector,
              {dynamic read: null}) : super(selector, read: read);
}

class ContentChildren extends Query {
  const ContentChildren(dynamic /* Type | String */ selector,
              {dynamic read: null}) : super(selector, read: read);
}

class Query extends DependencyMetadata {
  final dynamic /* Type | String */ selector;
  final dynamic /* String | Function? */ read;
  const DependencyMetadata(this.selector, {this.read}) : super();
}

class DependencyMetadata {
  const DependencyMetadata();
}

class TemplateRef {}
class ElementRef {}
class ViewContainerRef {}
class PipeTransform {}
''');
    newSource('/angular/src/core/ng_if.dart', r'''
import 'metadata.dart';

@Directive(selector: "[ngIf]")
class NgIf {
  @Input()
  NgIf(TemplateRef tpl);

  @Input()
  set ngIf(newCondition) {}
}
''');
    newSource('/angular/src/core/ng_for.dart', r'''
import 'metadata.dart';

@Directive(
    selector: "[ngFor][ngForOf]")
class NgFor {
  @Input()
  NgFor(TemplateRef tpl);
  @Input()
  set ngForOf(dynamic value) {}
  @Input()
  set ngForTrackBy(TrackByFn value) {}
}

typedef dynamic TrackByFn(num index, dynamic item);
''');
    newSource('/angular/src/security/dom_sanitization_service.dart', r'''
class SafeValue {}

abstract class SafeHtml extends SafeValue {}

abstract class SafeStyle extends SafeValue {}

abstract class SafeScript extends SafeValue {}

abstract class SafeUrl extends SafeValue {}

abstract class SafeResourceUrl extends SafeValue {}
''');
  }
}
