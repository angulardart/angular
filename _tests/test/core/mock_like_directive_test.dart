// @dart=2.9

import 'dart:async';

import 'package:test/test.dart';
import 'package:angular/angular.dart';
import 'package:angular_test/angular_test.dart';

import 'mock_like_directive_test.template.dart' as ng;

void main() {
  tearDown(disposeAnyRunningTest);

  test('should support null @Output if mock-like', () async {
    final testBed = NgTestBed(ng.createTestMockNotificationComponentFactory());
    await testBed.create();
  });

  test("shouldn't support null @Output if not mock-like", () async {
    final testBed = NgTestBed(ng.createTestFakeNotificationComponentFactory());
    expect(testBed.create(), throwsA(const TypeMatcher<NoSuchMethodError>()));
  });
}

@Component(
  selector: 'notifier',
  template: '',
)
class NotifierComponent {
  final StreamController<String> _notificationsController =
      StreamController<String>();

  @Output()
  Stream<String> get notifications => _notificationsController.stream;
}

@Component(
  selector: 'notifier',
  template: '',
)
class MockNotifierComponent implements NotifierComponent {
  @override
  Object noSuchMethod(Invocation invocation) => null;
}

@Component(
  selector: 'test-mock-notifier',
  template: '''
    <notifier (notifications)="notify(\$event)">
    </notifier>''',
  directives: [MockNotifierComponent],
)
class TestMockNotificationComponent {
  void notify(String notification) {}
}

@Component(
  selector: 'notifier',
  template: '',
)
class FakeNotifierComponent extends NotifierComponent {
  @override
  Stream<String> get notifications => null;
}

@Component(
  selector: 'test-fake-notifier',
  template: '''
    <notifier (notifications)="notify(\$event)">
    </notifier>''',
  directives: [FakeNotifierComponent],
)
class TestFakeNotificationComponent {
  void notify(String notification) {}
}
