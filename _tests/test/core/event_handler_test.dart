@TestOn('browser')
import 'dart:async';
import 'dart:html';

import 'package:angular/angular.dart';
import 'package:angular_test/angular_test.dart';
import 'package:test/test.dart';

import 'event_handler_test.template.dart' as ng;

void main() {
  tearDown(disposeAnyRunningTest);

  NgTestFixture<ClickHandler> fixture;

  group('Event handler', () {
    setUp(() async {
      final testBed = NgTestBed.forComponent(ng.ClickHandlerNgFactory);
      fixture = await testBed.create();
    });

    group('method call', () {
      test('should handle click with no args', () async {
        fixture.update((cmp) => cmp.noArgButton.click());
        expect(fixture.assertOnlyInstance.clicks, emits(null));
      });

      test('should handle click with one arg', () async {
        fixture.update((cmp) => cmp.oneArgButton.click());
        expect(fixture.assertOnlyInstance.clicks, emits(null));
      });
    });

    group('tearoffs', () {
      test('should handle click with no args', () async {
        fixture.update((cmp) => cmp.noArgTearoffButton.click());
        expect(fixture.assertOnlyInstance.clicks, emits(null));
      });

      test('should handle click with one arg', () async {
        fixture.update((cmp) => cmp.oneArgTearoffButton.click());
        expect(fixture.assertOnlyInstance.clicks, emits(null));
      });
    });
  });
}

@Component(
  selector: 'test',
  template: '''
  <button #noArg (click)="onClick()"></button>
  <button #oneArg (click)="clickWithEvent(\$event)"></button>
  <button #noArgTearoff (click)="onClick"></button>
  <button #oneArgTearoff (click)="clickWithEvent"></button>
  ''',
)
class ClickHandler {
  @ViewChild('noArg')
  HtmlElement noArgButton;

  @ViewChild('oneArg')
  HtmlElement oneArgButton;

  @ViewChild('noArgTearoff')
  HtmlElement noArgTearoffButton;

  @ViewChild('oneArgTearoff')
  HtmlElement oneArgTearoffButton;

  void onClick() {
    _clicks.add(null);
  }

  void clickWithEvent(Object event) {
    if (event != null) _clicks.add(null);
  }

  Stream get clicks => _clicks.stream;

  final StreamController _clicks = new StreamController();
}
