@JS()
library dart2js_golden;

import 'package:angular/angular.dart';
import 'package:js/js.dart';

import 'dart2js_golden.template.dart' as ng;

// Helps defeat tree-shaking in components below.
//
// This avoids something like `String x = 'Hello'` being aggressively inlined.
@JS()
external T defeatDart2JsOptimizations<T>(Object any);

/// This file entirely exists as synthetic AngularDart application.
///
/// The results, compiled with Dart2JS (without minification) are expected to
/// be checked in to `test/dart2js_golden.dart.js`, and must be regenerated
/// whenever the output would change.
///
/// See `../README.md` for details on updating the golden file.
///
/// **NOTE**: The test is not executed externally.
void main() {
  runApp(ng.RootComponentNgFactory);
}

@Component(
  selector: 'root-component',
  directives: [
    HasProvider,
    HasProviders,
    ComponentConditionalFeatures,
    UsesDefaultChangeDetectionAndInputs,
    UsesOnPushChangeDetectionAndInputs,
    InlinedNgIf,
    EmbeddedNgIf,
    EmbeddedNgFor,
    InjectsFromArbitraryParent,
    UsesDomBindings,
    UsesNgDirectives,
    HasNestedProviderLookups,
  ],
  template: r'''
    <div hasProviders>
      <div hasProvider></div>
    </div>
    <div hasProvider></div>
    <uses-default-change-detection-and-inputs>
    </uses-default-change-detection-and-inputs>
    <uses-on-push-change-detection-and-inputs>
    </uses-on-push-change-detection-and-inputs>
    <inlined-ng-if>
    </inlined-ng-if>
    <embedded-ng-if>
    </embedded-ng-if>
    <embedded-ng-for>
    </embedded-ng-for>
    <injects-from-arbitrary-parent>
    </injects-from-arbitrary-parent>
    <component-conditional-features [useFeatureA]="true" [useFeatureB]="false">
    </component-conditional-features>
    <uses-dom-bindings>
    </uses-dom-bindings>
    <uses-ng-directives>
    </uses-ng-directives>
    <has-nested-provider-lookups>
    </has-nested-provider-lookups>
  ''',
)
class RootComponent {}

class A {}

class B {}

class C {}

class C2 implements C {}

@Directive(
  selector: '[hasProvider]',
  providers: [
    ClassProvider(C, useClass: C2),
  ],
)
class HasProvider {}

@Directive(
  selector: '[hasProviders]',
  providers: [
    ClassProvider(A),
    ClassProvider(B),
    ClassProvider(C),
  ],
)
class HasProviders {}

@Component(
  selector: 'uses-default-change-detection-and-inputs',
  directives: [DefaultChangeDetectionAndInputs],
  template: r'''
    <default-change-detection-and-inputs [title]="title" [name]="name">
    </default-change-detection-and-inputs>
  ''',
)
class UsesDefaultChangeDetectionAndInputs {
  final String title = defeatDart2JsOptimizations('title');
  String name = defeatDart2JsOptimizations('name');
}

@Component(
  selector: 'default-change-detection-and-inputs',
  template: 'Hello {{title}} {{name}}',
)
class DefaultChangeDetectionAndInputs {
  @Input()
  String title;

  @Input()
  String name;
}

@Component(
  selector: 'uses-on-push-change-detection-and-inputs',
  directives: [OnPushChangeDetectionAndInputs],
  template: r'''
    <on-push-change-detection-and-inputs [title]="title" [name]="name">
    </on-push-change-detection-and-inputs>
  ''',
)
class UsesOnPushChangeDetectionAndInputs {
  final String title = defeatDart2JsOptimizations('title');
  String name = defeatDart2JsOptimizations('name');
}

@Component(
  selector: 'on-push-change-detection-and-inputs',
  template: 'Hello {{title}} {{name}}',
  changeDetection: ChangeDetectionStrategy.OnPush,
)
class OnPushChangeDetectionAndInputs {
  @Input()
  String title;

  @Input()
  String name;
}

@Component(
  selector: 'inlined-ng-if',
  directives: [
    NgIf,
  ],
  template: r'''
    <div *ngIf="showDiv">Hello World</div>
  ''',
)
class InlinedNgIf {
  bool showDiv = defeatDart2JsOptimizations('showDiv');
}

@Component(
  selector: 'embedded-ng-if',
  directives: [
    NgIf,
    NullComponent,
  ],
  template: r'''
    <null *ngIf="showNull"></null>
  ''',
)
class EmbeddedNgIf {
  bool showNull = defeatDart2JsOptimizations('showNull');
}

@Component(
  selector: 'embedded-ng-for',
  directives: [
    NgFor,
  ],
  template: r'''
    <ul>
      <li *ngFor="let item of items">{{item}}</li>
    </ul>
  ''',
)
class EmbeddedNgFor {
  final items = ['foo', 'bar', 'baz'];
}

@Component(
  selector: 'null',
  template: '',
)
class NullComponent {}

const injectsUsPresidents = MultiToken<String>('usPresidents');
const injectsWhiteHouse = MultiToken<String>('whiteHouse');

class InjectableService {
  void printWashingtonDc(String whiteHouse, List<String> usPresidents) {
    print('$whiteHouse: ${usPresidents.join(', ')}');
  }
}

@Component(
  selector: 'injects-from-arbitrary-parent',
  template: '',
)
class InjectsFromArbitraryParent {
  InjectsFromArbitraryParent(
    @injectsUsPresidents List<String> usPresidents,
    @injectsWhiteHouse String whiteHouse,
    InjectableService service,
  ) {
    service.printWashingtonDc(whiteHouse, usPresidents);
  }
}

@Component(
  selector: 'component-conditional-features',
  directives: [
    FeatureA,
    FeatureB,
    NgIf,
  ],
  template: r'''
    <feature-a *ngIf="useFeatureA"></feature-a>
    <feature-b *ngIf="useFeatureB"></feature-b>
  ''',
)
class ComponentConditionalFeatures {
  @Input()
  bool useFeatureA = false;

  @Input()
  bool useFeatureB = false;
}

@Component(
  selector: 'feature-a',
  template: 'I am Feature A',
)
class FeatureA {}

@Component(
  selector: 'feature-b',
  template: 'I am Feature B',
)
class FeatureB {}

@Component(
  selector: 'uses-dom-bindings',
  template: r'''
    <button [attr.title]="title" [class.fancy]="isFancy"></button>
  ''',
)
class UsesDomBindings {
  @HostBinding('attr.title')
  String get title => defeatDart2JsOptimizations('title');

  @HostBinding('class.fancy')
  bool get isFancy => defeatDart2JsOptimizations('fancy');
}

@Component(
  selector: 'uses-ng-directives',
  directives: [
    NgClass,
    NgStyle,
  ],
  template: r'''
    <div [ngClass]="ngClassesMap">Classes From Map</div>
    <div [ngClass]="ngClassesList">Classes from List</div>
    <div [ngClass]="ngClassesString">Classes from String</div>
    <div [ngStyle]="ngStyles">Styles</div>
  ''',
)
class UsesNgDirectives {
  var ngClassesMap = {
    'foo': true,
    'bar': false,
  };

  var ngClassesList = [
    'foo',
    'bar',
  ];

  var ngClassesString = 'foo bar';

  var ngStyles = {
    'height': '100px',
    'width': '50px',
  };
}

@Component(
  selector: 'has-nested-provider-lookups',
  directives: [
    InjectsManyThingsDynamically,
    NgIf,
  ],
  template: r'''
    <div *ngIf="maybe1">
      <div *ngIf="maybe2">
        <injects-many-things-dynamically></injects-many-things-dynamically>
      </div>
    </div>
  ''',
)
class HasNestedProviderLookups {
  var maybe1 = true;
  var maybe2 = true;
}

@Component(
  selector: 'injects-many-things-dynamically',
  template: '',
)
class InjectsManyThingsDynamically {
  @pragma('dart2js:noInline')
  InjectsManyThingsDynamically(
    DepA a,
    DepB b,
    DepC c,
    @Optional() DepD d,
    @Optional() DepE e,
    @Optional() DepF f,
  ) {
    defeatDart2JsOptimizations([a, b, c, d, e, f]);
  }
}

class DepA {}

class DepB {}

class DepC {}

class DepD {}

class DepE {}

class DepF {}
