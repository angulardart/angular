import 'package:angular/angular.dart';

import 'dart2js_golden.template.dart' as ng;

// Helps defeat tree-shaking in components below.
//
// This avoids something like `String x = 'Hello'` being aggressively inlined.
final _emptyMap = <Object, Object>{};

/// This file entirely exists as synthetic AngularDart application.
///
/// The results, compiled with Dart2JS (without minification) are expected to
/// be checked in to `test/dart2js_golden.dart.js`, and must be regenerated
/// whenever the output would change.
///
/// See .`./README.md` for details on updating the golden file.
///
/// **NOTE**: The test is not executed externally.
void main() {
  runApp(ng.RootComponentNgFactory);
}

@Component(
  selector: 'root-component',
  directives: [
    UsesDefaultChangeDetectionAndInput,
    InlinedNgIf,
    EmbeddedNgIf,
    InjectsFromArbitraryParent
  ],
  template: r'''
    <uses-default-change-detection-and-input>
    </uses-default-change-detection-and-input>
    <inlined-ng-if>
    </inlined-ng-if>
    <embedded-ng-if>
    </embedded-ng-if>
    <injects-from-arbitrary-parent>
    </injects-from-arbitrary-parent>
  ''',
)
class RootComponent {}

@Component(
  selector: 'uses-default-change-detection-and-input',
  template: r'''
    <default-change-detection-and-input [name]="name">
    </default-change-detection-and-input>
  ''',
)
class UsesDefaultChangeDetectionAndInput {
  String name = _emptyMap['String'];
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
  bool showDiv = _emptyMap['bool'];
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
  bool showNull = _emptyMap['bool'];
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
