import 'package:test/test.dart';
import 'package:angular/angular.dart';
import 'package:angular_test/angular_test.dart';

import 'after_changes_test.template.dart' as ng;

void main() {
  tearDown(disposeAnyRunningTest);

  test('should be called at least once on initial load', () async {
    final testBed = NgTestBed(
      ng.createTestAfterChangesFactory(),
    );
    final fixture = await testBed.create(beforeChangeDetection: (instance) {
      instance
        ..name = 'Buzz Lightyear'
        ..email = 'buzz@starcommand.com';
    });
    expect(fixture.text, 'Buzz Lightyear (buzz@starcommand.com)');
    expect(AfterChangesExample.ngAfterChangesCalled, 1);
  });

  test('should be called after there is a change to an @Input', () async {
    final testBed = NgTestBed(
      ng.createTestAfterChangesFactory(),
    );
    final fixture = await testBed.create();
    expect(fixture.text, isEmpty);
    expect(AfterChangesExample.ngAfterChangesCalled, 0);

    await fixture.update((instance) {
      instance
        ..name = 'Buzz Lightyear'
        ..email = 'buzz@starcommand.com';
    });
    expect(fixture.text, 'Buzz Lightyear (buzz@starcommand.com)');
    expect(AfterChangesExample.ngAfterChangesCalled, 1);

    await fixture.update((instance) {
      instance.email = 'buzz@andy.com';
    });
    expect(fixture.text, 'Buzz Lightyear (buzz@andy.com)');
    expect(AfterChangesExample.ngAfterChangesCalled, 2);
  });

  test('should be skipped if inputs do not change identity', () async {
    final testBed = NgTestBed(
      ng.createTestAfterChangesFactory(),
    );
    final fixture = await testBed.create();
    expect(fixture.text, isEmpty);
    expect(AfterChangesExample.ngAfterChangesCalled, 0);

    await fixture.update((instance) {
      instance
        ..name = 'Buzz Lightyear'
        ..email = 'buzz@starcommand.com';
    });
    expect(fixture.text, 'Buzz Lightyear (buzz@starcommand.com)');
    expect(AfterChangesExample.ngAfterChangesCalled, 1);

    await fixture.update((instance) {
      instance.email = 'buzz@starcommand.com';
    });
    expect(fixture.text, 'Buzz Lightyear (buzz@starcommand.com)');
    expect(AfterChangesExample.ngAfterChangesCalled, 1);
  });

  test('should also be supported on a @Directive', () async {
    final testBed = NgTestBed(
      ng.createTestAfterChangesDirectiveFactory(),
    );
    final fixture = await testBed.create(beforeChangeDetection: (instance) {
      instance.name = 'Buzz Lightyear';
    });
    expect(AfterChangesDirectiveExample.ngAfterChangesCalled, 1);

    await fixture.update((i) => i.name = 'Woody');
    expect(AfterChangesDirectiveExample.ngAfterChangesCalled, 2);

    await fixture.update((i) => i.name = 'Woody');
    expect(AfterChangesDirectiveExample.ngAfterChangesCalled, 2);
  });
}

@Component(
  selector: 'test-after-changes-example',
  directives: [
    AfterChangesExample,
  ],
  template: r'''
    <after-changes-example [name]="name" [email]="email">
    </after-changes-example>
  ''',
)
class TestAfterChanges {
  String? name;
  String? email;
}

@Component(
  selector: 'after-changes-example',
  template: '{{nameAndEmail}}',
)
class AfterChangesExample implements AfterChanges {
  static var ngAfterChangesCalled = 0;

  AfterChangesExample() {
    ngAfterChangesCalled = 0;
  }

  @Input()
  String? name;

  @Input()
  String? email;

  @override
  void ngAfterChanges() {
    ngAfterChangesCalled++;
    if (name != null && email != null) {
      nameAndEmail = '$name ($email)';
    } else {
      nameAndEmail = '';
    }
  }

  String nameAndEmail = '';
}

@Component(
  selector: 'test-after-changes-directive',
  directives: [
    AfterChangesDirectiveExample,
  ],
  template: r'''
    <div after-changes-directive [name]="name">
    </div>
  ''',
)
class TestAfterChangesDirective {
  String? name;
}

@Directive(
  selector: '[after-changes-directive]',
)
class AfterChangesDirectiveExample implements AfterChanges {
  static var ngAfterChangesCalled = 0;

  @Input()
  String? name;

  @override
  void ngAfterChanges() {
    ngAfterChangesCalled++;
  }
}
