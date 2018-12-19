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
    ComponentConditionalFeatures,
    UsesDefaultChangeDetectionAndInput,
    InlinedNgIf,
    EmbeddedNgIf,
    EmbeddedNgFor,
    InjectsFromArbitraryParent
  ],
  template: r'''
    <uses-default-change-detection-and-input>
    </uses-default-change-detection-and-input>
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
  ''',
)
class RootComponent {}

@Component(
  selector: 'uses-default-change-detection-and-input',
  directives: [DefaultChangeDetectionAndInput],
  template: r'''
    <default-change-detection-and-input [name]="name">
    </default-change-detection-and-input>
  ''',
)
class UsesDefaultChangeDetectionAndInput {
  String name = defeatDart2JsOptimizations('name');
}

@Component(
  selector: 'default-change-detection-and-input',
  template: 'Hello {{name}}',
)
class DefaultChangeDetectionAndInput {
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
