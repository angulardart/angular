@TestOn('browser')
library angular2.test.compiler.runtime_metadata_test;

import 'package:angular2/core.dart'
    show
        Component,
        Directive,
        ViewEncapsulation,
        ChangeDetectionStrategy,
        OnChanges,
        OnInit,
        DoCheck,
        OnDestroy,
        AfterContentInit,
        AfterContentChecked,
        AfterViewInit,
        AfterViewChecked,
        SimpleChange,
        provide;
import 'package:angular2/src/compiler/runtime_metadata.dart'
    show RuntimeMetadataResolver;
import 'package:angular2/src/compiler/util.dart' show MODULE_SUFFIX;
import 'package:angular2/src/core/metadata/lifecycle_hooks.dart'
    show LIFECYCLE_HOOKS_VALUES;
import 'package:angular2/src/core/platform_directives_and_pipes.dart'
    show PLATFORM_DIRECTIVES;
import 'package:angular2/src/facade/lang.dart' show stringify;
import 'package:angular2/testing_internal.dart';
import 'package:test/test.dart';

import 'test_bindings.dart' show TEST_PROVIDERS;

main() {
  beforeEachProviders(() => TEST_PROVIDERS);
  group('RuntimeMetadataResolver getMetadata', () {
    test('should read metadata', () async {
      return inject([RuntimeMetadataResolver],
          (RuntimeMetadataResolver resolver) {
        var meta = resolver.getDirectiveMetadata(ComponentWithEverything);
        expect(meta.selector, 'someSelector');
        expect(meta.exportAs, 'someExportAs');
        expect(meta.isComponent, isTrue);
        expect(meta.type.runtime, ComponentWithEverything);
        expect(meta.type.name, stringify(ComponentWithEverything));
        expect(meta.type.moduleUrl, 'package:someModuleId${ MODULE_SUFFIX}');
        expect(meta.lifecycleHooks, LIFECYCLE_HOOKS_VALUES);
        expect(meta.changeDetection, ChangeDetectionStrategy.CheckAlways);
        expect(meta.inputs, {'someProp': 'someProp'});
        expect(meta.outputs, {'someEvent': 'someEvent'});
        expect(
            meta.hostListeners, {'someHostListener': 'someHostListenerExpr'});
        expect(meta.hostProperties, {'someHostProp': 'someHostPropExpr'});
        expect(meta.hostAttributes, {'someHostAttr': 'someHostAttrValue'});
        expect(meta.template.encapsulation, ViewEncapsulation.Emulated);
        expect(meta.template.styles, ['someStyle']);
        expect(meta.template.styleUrls, ['someStyleUrl']);
        expect(meta.template.template, 'someTemplate');
        expect(meta.template.templateUrl, 'someTemplateUrl');
      });
    });
    test('should use the moduleUrl from the reflector if none is given',
        () async {
      return inject([RuntimeMetadataResolver],
          (RuntimeMetadataResolver resolver) {
        String value = resolver
            .getDirectiveMetadata(ComponentWithoutModuleId)
            .type
            .moduleUrl;
        expect(
            value.endsWith('test/compiler/runtime_metadata_test.dart'), isTrue);
      });
    });
  });
  group('getViewDirectivesMetadata', () {
    test('should return the directive metadatas', () async {
      return inject([RuntimeMetadataResolver],
          (RuntimeMetadataResolver resolver) {
        expect(resolver.getViewDirectivesMetadata(ComponentWithEverything),
            contains(resolver.getDirectiveMetadata(SomeDirective)));
      });
    });
    group('platform directives', () {
      beforeEachProviders(() => [
            provide(PLATFORM_DIRECTIVES, useValue: [ADirective], multi: true)
          ]);
      test('should include platform directives when available', () async {
        return inject([RuntimeMetadataResolver],
            (RuntimeMetadataResolver resolver) {
          expect(resolver.getViewDirectivesMetadata(ComponentWithEverything),
              contains(resolver.getDirectiveMetadata(ADirective)));
          expect(resolver.getViewDirectivesMetadata(ComponentWithEverything),
              contains(resolver.getDirectiveMetadata(SomeDirective)));
        });
      });
    });
  });
}

@Directive(selector: 'a-directive')
class ADirective {}

@Directive(selector: 'someSelector')
class SomeDirective {}

@Component(selector: 'someComponent', template: '')
class ComponentWithoutModuleId {}

@Component(
    selector: 'someSelector',
    inputs: const ['someProp'],
    outputs: const ['someEvent'],
    host: const {
      '[someHostProp]': 'someHostPropExpr',
      '(someHostListener)': 'someHostListenerExpr',
      'someHostAttr': 'someHostAttrValue'
    },
    exportAs: 'someExportAs',
    moduleId: 'someModuleId',
    changeDetection: ChangeDetectionStrategy.CheckAlways,
    template: 'someTemplate',
    templateUrl: 'someTemplateUrl',
    encapsulation: ViewEncapsulation.Emulated,
    styles: const ['someStyle'],
    styleUrls: const ['someStyleUrl'],
    directives: const [SomeDirective])
class ComponentWithEverything
    implements
        OnChanges,
        OnInit,
        DoCheck,
        OnDestroy,
        AfterContentInit,
        AfterContentChecked,
        AfterViewInit,
        AfterViewChecked {
  void ngOnChanges(Map<String, SimpleChange> changes) {}
  void ngOnInit() {}
  void ngDoCheck() {}
  void ngOnDestroy() {}
  void ngAfterContentInit() {}
  void ngAfterContentChecked() {}
  void ngAfterViewInit() {}
  void ngAfterViewChecked() {}
}
