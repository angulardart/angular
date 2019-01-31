@TestOn('browser')
import 'dart:html';

import 'package:angular/angular.dart';
import 'package:angular_test/angular_test.dart';
import 'package:test/test.dart';

import 'i18n_escape_test.template.dart' as ng;

const message = "\\ It's\n\$12.00";
final regExp = RegExp(r"\\ It's\s*\$12\.00");

void main() {
  tearDown(disposeAnyRunningTest);

  group('should escape special characters in', () {
    test('text', () async {
      final testBed = NgTestBed.forComponent(ng.ShouldEscapeI18nTextNgFactory);
      final testFixture = await testBed.create();
      expect(testFixture.text, matches(regExp));
    });

    test('text with HTML', () async {
      final testBed = NgTestBed.forComponent(ng.ShouldEscapeI18nHtmlNgFactory);
      final testFixture = await testBed.create();
      expect(testFixture.text, matches(regExp));
    });

    test('attributes', () async {
      final testBed =
          NgTestBed.forComponent(ng.ShouldEscapeI18nAttributeNgFactory);
      final testFixture = await testBed.create();
      final element = testFixture.rootElement.querySelector('[foo]');
      expect(element.getAttribute('foo'), matches(regExp));
    });

    test('properties', () async {
      final testBed =
          NgTestBed.forComponent(ng.ShouldEscapeI18nPropertyNgFactory);
      final testFixture = await testBed.create();
      final imgElement =
          testFixture.rootElement.querySelector('img') as ImageElement;
      expect(imgElement.alt, matches(regExp));
    });

    test('inputs', () async {
      final testBed = NgTestBed.forComponent(ng.ShouldEscapeI18nInputNgFactory);
      final testFixture = await testBed.create();
      expect(testFixture.assertOnlyInstance.greeting.message, matches(regExp));
    });
  });
}

@Component(
  selector: 'test',
  template: '''
    <ng-container @i18n="A message with characters that should be escaped">
      $message
    </ng-container>
  ''',
)
class ShouldEscapeI18nText {}

@Component(
  selector: 'test',
  template: '''
    <ng-container @i18n="A message with characters that should be escaped">
      <strong>$message</strong>!
    </ng-container>
  ''',
)
class ShouldEscapeI18nHtml {}

@Component(
  selector: 'test',
  template: '''
    <div
        foo="$message"
        @i18n:foo="A message with characters that should be escaped">
    </div>
   ''',
)
class ShouldEscapeI18nAttribute {}

@Component(
  selector: 'test',
  template: '''
    <img
        alt="$message"
        @i18n:alt="A message with characters that should be escaped">
  ''',
)
class ShouldEscapeI18nProperty {}

@Component(
  selector: 'greeting',
  template: '',
)
class GreetingComponent {
  @Input()
  String message;
}

@Component(
  selector: 'test',
  template: r'''
    <greeting
        [message]="'\\ It\'s\n$12.00'"
        @i18n:message="A message with characters that should be escaped">
    </greeting>
  ''',
  directives: [GreetingComponent],
)
class ShouldEscapeI18nInput {
  @ViewChild(GreetingComponent)
  GreetingComponent greeting;
}
