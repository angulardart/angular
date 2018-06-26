@TestOn('browser')
import 'dart:async';

import 'package:test/test.dart';
import 'package:angular/angular.dart';
import 'package:angular_forms/angular_forms.dart';
import 'package:angular_test/angular_test.dart';

import 'validator_directives_test.template.dart' as ng;

void main() {
  group('RequiredValidator', () {
    NgTestFixture<DynamicRequiredComponent> fixture;

    setUp(() async {
      var testBed =
          NgTestBed.forComponent(ng.DynamicRequiredComponentNgFactory);
      fixture = await testBed.create();
    });

    tearDown(() => disposeAnyRunningTest());

    Future<void> updateRequired({bool required}) async {
      await fixture.update((cmp) => cmp.required = required);
      // We have to do this in a separate turn, so that new required value has
      // propagated.
      await fixture
          .update((cmp) => cmp.dynamicControl.control.updateValueAndValidity());
    }

    bool dynamicControlValid() =>
        fixture.assertOnlyInstance.dynamicControl.valid;

    test('can be triggered dynamically', () async {
      expect(dynamicControlValid(), true);

      await updateRequired(required: true);

      expect(dynamicControlValid(), false);

      await fixture.update((cmp) => cmp.value = 'abc');

      expect(dynamicControlValid(), true);

      await updateRequired(required: false);

      expect(dynamicControlValid(), true);

      await fixture.update((cmp) => cmp.value = '');

      expect(dynamicControlValid(), true);
    });

    test('can be set statically', () {
      expect(fixture.assertOnlyInstance.staticControl.valid, false);
    });
  });
}

@Component(
  selector: 'dynamic-required',
  template: '''
<div ngForm>
  <input
      [(ngModel)]="value"
      ngControl="dynamic"
      #dynamicControl="ngForm"
      [required]="required" />
  <input
      [(ngModel)]="value"
      ngControl="static"
      #staticControl="ngForm"
      required />
</div>
  ''',
  directives: [formDirectives],
)
class DynamicRequiredComponent {
  String value = '';
  bool required = false;

  @ViewChild('dynamicControl')
  NgControl dynamicControl;

  @ViewChild('staticControl')
  NgControl staticControl;
}
