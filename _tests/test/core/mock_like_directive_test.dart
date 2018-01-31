@Tags(const ['codegen'])
@TestOn('browser')

import 'dart:async';

import 'package:test/test.dart';
import 'package:angular/angular.dart';
import 'package:angular_test/angular_test.dart';

import 'mock_like_directive_test.template.dart' as ng_generated;

void main() {
  ng_generated.initReflector();

  tearDown(disposeAnyRunningTest);

  test('should support null @Output if mock-like', () async {
    final testBed = new NgTestBed<TestMockNotificationComponent>();
    await testBed.create();
  });

  test("shouldn't support null @Output if not mock-like", () async {
    final testBed = new NgTestBed<TestFakeNotificationComponent>();
    expect(testBed.create(),
        throwsInAngular(new isInstanceOf<NoSuchMethodError>()));
  });
}

@Component(
  selector: 'notifier',
  template: '',
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class NotifierComponent {
  final StreamController<String> _notificationsController =
      new StreamController<String>();

  @Output()
  Stream<String> get notifications => _notificationsController.stream;
}

@Component(
  selector: 'notifier',
  template: '',
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class MockNotifierComponent implements NotifierComponent {
  noSuchMethod(Invocation invocation) => null;
}

@Component(
  selector: 'test-mock-notifier',
  template: '''
    <notifier (notifications)="notify(\$event)">'
    </notifier>''',
  directives: const [MockNotifierComponent],
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class TestMockNotificationComponent {
  void notify(String notification) {}
}

@Component(
  selector: 'notifier',
  template: '',
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class FakeNotifierComponent extends NotifierComponent {
  Stream<String> get notifications => null;
}

@Component(
  selector: 'test-fake-notifier',
  template: '''
    <notifier (notifications)="notify(\$event)">'
    </notifier>''',
  directives: const [FakeNotifierComponent],
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class TestFakeNotificationComponent {
  void notify(String notification) {}
}
