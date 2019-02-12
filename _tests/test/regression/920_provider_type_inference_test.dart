@TestOn('browser')
import 'package:test/test.dart';
import 'package:angular/angular.dart';
import 'package:angular_test/angular_test.dart';

import '920_provider_type_inference_test.template.dart' as ng_generated;

void main() {
  test('should use the provided type with component providers', () async {
    final testBed = NgTestBed.forComponent(
      ng_generated.CompProvidesUsPresidentsNgFactory,
    );
    final fixture = await testBed.create();
    final childComp = fixture.assertOnlyInstance.child;

    // Prior to the fix of #920, this was always provided as List<dynamic>.
    expect(
      childComp.injectedList,
      const TypeMatcher<List<String>>(),
      reason: 'Got ${childComp.injectedList?.runtimeType} not List<String>',
    );
  });
}

const usPresidents = OpaqueToken<List<String>>('usPresidents');

@Component(
  selector: 'comp',
  directives: [
    ChildComp,
  ],
  providers: [
    Provider<List<String>>(usPresidents, useValue: [
      'George Washington',
      'Abraham Lincoln',
    ]),
  ],
  template: '<child></child>',
)
class CompProvidesUsPresidents {
  @ViewChild(ChildComp)
  ChildComp child;
}

@Component(
  selector: 'child',
  template: '',
)
class ChildComp {
  // Intentionally not List<String>, that is the regression test :)
  final Object injectedList;

  ChildComp(@usPresidents this.injectedList);
}
