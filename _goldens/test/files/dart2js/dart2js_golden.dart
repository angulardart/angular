@JS()
library dart2js_golden;

import 'dart:async';

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
  runApp(ng.RootComponentNgFactory, createInjector: doGenerate);
}

@Component(
  selector: 'root-component',
  directives: [
    NgIf,
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
    HasHostListeners,
    OnPushChild,
    Child,
    HasContentChildren,
    HasViewChildren,
    HasLargeProviders,
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
    <has-host-listeners>
    </has-host-listeners>
    <has-content-children>
      <child></child>
      <child onPush></child>
      <ng-container *ngIf="false">
        <child></child>
      </ng-container>
    </has-content-children>
    <has-view-children>
    </has-view-children>
    <has-large-providers>
    </has-large-providers>
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
  template: 'Hello {{title}} {{name}} {{3}} {{null}}',
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
class OnPushChangeDetectionAndInputs implements OnInit, OnDestroy {
  OnPushChangeDetectionAndInputs(this._changeDetector, this._stream);

  final ChangeDetectorRef _changeDetector;
  final Stream<void> _stream;

  StreamSubscription<void> _subscription;

  @Input()
  String title;

  @Input()
  String name;

  @override
  void ngOnInit() {
    _subscription = _stream.listen((_) {
      _changeDetector.markForCheck();
    });
  }

  @override
  void ngOnDestroy() {
    _subscription.cancel();
  }
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

@Component(
  selector: 'has-host-listeners',
  template: '',
)
class HasHostListeners {
  @HostListener('click')
  void onClick() {}

  @HostListener('focus')
  void onFocus() {}
}

@Component(
  selector: 'child',
  template: '',
)
class Child {}

@Component(
  selector: 'child[onPush]',
  template: '',
  providers: [
    ExistingProvider(Child, OnPushChild),
  ],
  changeDetection: ChangeDetectionStrategy.OnPush,
)
class OnPushChild implements Child {}

@Component(
  selector: 'has-content-children',
  template: '<ng-content></ng-content>',
)
class HasContentChildren {
  @ContentChildren(Child)
  set children(List<Child> value) => defeatDart2JsOptimizations(value);
}

@Component(
  selector: 'has-view-children',
  template: '''
      <child onPush></child>
      <child></child>
      <ng-container *ngIf="false">
        <child></child>
        <child onPush></child>
      </ng-container>
      <child></child>
  ''',
  directives: [OnPushChild, Child, NgIf],
)
class HasViewChildren {
  @ViewChildren(Child)
  set children(List<Child> value) => defeatDart2JsOptimizations(value);
}

const _largeProviderList = [
  // Heavy use of ExistingProvider + lots of dependencies.
  ClassProvider(UtilA0),
  ClassProvider(UtilA1),
  ClassProvider(UtilA2),
  ClassProvider(UtilA3),
  ClassProvider(UtilA4),
  ClassProvider(UtilA5),
  ClassProvider(UtilA6),
  ClassProvider(UtilA7),
  ClassProvider(UtilA8),
  ClassProvider(UtilA9),
  ExistingProvider(UtilB0, UtilA0),
  ExistingProvider(UtilB1, UtilA1),
  ExistingProvider(UtilB2, UtilA2),
  ExistingProvider(UtilB3, UtilA3),
  ExistingProvider(UtilB4, UtilA4),
  ExistingProvider(UtilB5, UtilA5),
  ExistingProvider(UtilB6, UtilA6),
  ExistingProvider(UtilB7, UtilA7),
  ExistingProvider(UtilB8, UtilA8),
  ExistingProvider(UtilB9, UtilA9),
  ClassProvider(AppUtil),
  ClassProvider(BaseUtil)
];

// Uses patterns that were found to be used extensively in large apps.
@GenerateInjector([
  ..._largeProviderList,
])
final InjectorFactory doGenerate = ng.doGenerate$Injector;

class BaseAppModel {}

class SuperAppModel extends BaseAppModel {}

class UtilA0 {}

class UtilA1 {}

class UtilA2 {}

class UtilA3 {}

class UtilA4 {}

class UtilA5 {}

class UtilA6 {}

class UtilA7 {}

class UtilA8 {}

class UtilA9 {}

class UtilB0 extends UtilA0 {}

class UtilB1 extends UtilA1 {}

class UtilB2 extends UtilA2 {}

class UtilB3 extends UtilA3 {}

class UtilB4 extends UtilA4 {}

class UtilB5 extends UtilA5 {}

class UtilB6 extends UtilA6 {}

class UtilB7 extends UtilA7 {}

class UtilB8 extends UtilA8 {}

class UtilB9 extends UtilA9 {}

class BaseUtil {}

class AppUtil extends BaseUtil {
  AppUtil(
    UtilB0 b0,
    UtilB1 b1,
    UtilB2 b2,
    UtilB3 b3,
    UtilB4 b4,
    UtilB5 b5,
    UtilB6 b6,
    UtilB7 b7,
    UtilB8 b8,
    UtilB9 b9,
  ) {
    defeatDart2JsOptimizations([
      b0,
      b1,
      b2,
      b3,
      b4,
      b5,
      b6,
      b7,
      b8,
      b9,
    ]);
  }
}

@Component(
  selector: 'has-large-providers',
  template: '',
  providers: [
    ..._largeProviderList,
  ],
)
class HasLargeProviders {
  HasLargeProviders(Injector i) {
    defeatDart2JsOptimizations(i);
  }
}
