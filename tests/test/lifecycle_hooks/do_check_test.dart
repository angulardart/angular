import 'package:test/test.dart';
import 'package:angular/angular.dart';
import 'package:angular_test/angular_test.dart';

import 'do_check_test.template.dart' as ng;

void main() {
  debugCheckBindings();

  tearDown(disposeAnyRunningTest);

  test('should call ngDoCheck initially', () async {
    final testBed = NgTestBed(
      ng.createTestDoCheckHookFactory(),
    );
    final fixture = await testBed.create(
      beforeChangeDetection: (i) => i.animals = ['Dog', 'Cat', 'Dog'],
    );
    expect(fixture.text, 'Number of Dogs: 2');
  });

  test('should call input setters initially', () async {
    final testBed = NgTestBed(
      ng.createTestDoCheckSetterFactory(),
    );
    final fixture = await testBed.create(
      beforeChangeDetection: (i) => i.animals = ['Dog', 'Cat', 'Dog'],
    );
    expect(fixture.text, 'Number of Dogs: 2');
  });

  test('should call ngDoCheck after each update', () async {
    final testBed = NgTestBed(
      ng.createTestDoCheckHookFactory(),
    );
    final fixture = await testBed.create(
      beforeChangeDetection: (i) => i.animals = ['Dog', 'Cat', 'Dog'],
    );
    expect(fixture.text, 'Number of Dogs: 2');

    await fixture.update((i) => i.animals.add('Dog'));
    expect(fixture.text, 'Number of Dogs: 3');
  });

  test('should call input setters only when changed', () async {
    final testBed = NgTestBed(
      ng.createTestDoCheckSetterFactory(),
    );
    final fixture = await testBed.create(
      beforeChangeDetection: (i) => i.animals = ['Dog', 'Cat', 'Dog'],
    );
    expect(fixture.text, 'Number of Dogs: 2');

    await fixture.update((i) => i.animals.add('Dog'));
    expect(
      fixture.text,
      'Number of Dogs: 2',
      reason: '<Component>.animals=\'s identity was not changed',
    );
  });
}

@Component(
  selector: 'test-do-check-hook',
  directives: [
    DoCheckExample1,
  ],
  template: r'''
    <do-check-example-1 [animals]="animals">
    </do-check-example-1>
  ''',
)
class TestDoCheckHook {
  List<String> animals = [];
}

@Component(
  selector: 'test-do-check-setter',
  directives: [
    DoCheckExample2,
  ],
  template: r'''
    <do-check-example-2 [animals]="animals">
    </do-check-example-2>
  ''',
)
class TestDoCheckSetter {
  List<String> animals = [];
}

@Component(
  selector: 'do-check-example-1',
  template: r'''
    Number of Dogs: {{countDogs}}
  ''',
)
class DoCheckExample1 implements DoCheck {
  var countDogs = 0;

  @Input()
  List<String> animals = [];

  @override
  void ngDoCheck() {
    // Called after the end of every CD cycle, similar to ngAfterChanges.
    countDogs = animals.where((a) => a == 'Dog').length;
  }
}

@Component(
  selector: 'do-check-example-2',
  template: r'''
    Number of Dogs: {{countDogs}}
  ''',
)
class DoCheckExample2 implements DoCheck {
  var countDogs = 0;

  @Input()
  set animals(List<String> animals) {
    // This setter is not called every CD cycle.
    countDogs = animals.where((a) => a == 'Dog').length;
  }

  @override
  void ngDoCheck() {
    // Intentionally empty.
  }
}
