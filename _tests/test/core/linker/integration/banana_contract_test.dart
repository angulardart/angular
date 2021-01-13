import 'dart:async';

import 'package:test/test.dart';
import 'package:angular/angular.dart';
import 'package:angular_test/angular_test.dart';

import 'banana_contract_test.template.dart' as ng;

void main() {
  tearDown(disposeAnyRunningTest);

  test('value of a binding desynchronizes when a change is rejected', () async {
    final testBed = NgTestBed<RejectionCaseComponent>(
      ng.createRejectionCaseComponentFactory(),
    );
    final fixture = await testBed.create();

    // Initial values.
    expect(fixture.assertOnlyInstance.value, false);
    expect(fixture.assertOnlyInstance.input!.value, false);

    // Bind to true, let it propagate down.
    await fixture.update((instance) {
      instance.value = true;
    });

    expect(fixture.assertOnlyInstance.value, true);
    expect(fixture.assertOnlyInstance.input!.value, true);

    // Emit to false, let it propagate up.
    await fixture.update((instance) {
      instance.input!.change(false);
    });

    expect(fixture.assertOnlyInstance.value, false);
    expect(fixture.assertOnlyInstance.input!.value, false);

    // Emit to true, "reject" the event value.
    await fixture.update((instance) {
      instance
        ..reject = true
        ..input!.change(true);
    });

    expect(fixture.assertOnlyInstance.value, false);
    expect(fixture.assertOnlyInstance.input!.value, true);
  });
}

@Component(
  selector: 'rejection-case',
  directives: [
    ExampleInputComponent,
  ],
  template: r'''
    <example-input [(value)]="value"></example-input>
  ''',
)
class RejectionCaseComponent {
  var _value = false;

  bool get value => _value;

  set value(bool value) {
    if (reject) {
      return;
    }
    _value = value;
  }

  @Input()
  var reject = false;

  @ViewChild(ExampleInputComponent)
  ExampleInputComponent? input;
}

@Component(
  selector: 'example-input',
  template: '',
)
class ExampleInputComponent {
  final _valueChange = StreamController<bool>.broadcast();

  @Input()
  var value = false;

  @Output()
  Stream<bool> get valueChange => _valueChange.stream;

  void change(bool newValue) {
    _valueChange.add(value = newValue);
  }
}
