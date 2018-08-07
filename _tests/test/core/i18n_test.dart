@TestOn('browser')
import 'package:angular/angular.dart';
import 'package:angular_test/angular_test.dart';
import 'package:test/test.dart';

import 'i18n_test.template.dart' as ng;

void main() {
  tearDown(disposeAnyRunningTest);

  test('should render message', () async {
    final testBed = NgTestBed.forComponent(ng.TestI18nNodeNgFactory);
    final testFixture = await testBed.create();
    expect(testFixture.text, 'A message.');
  });

  test('should render message in attribute', () async {
    final testBed = NgTestBed.forComponent(ng.TestI18nAttributeNgFactory);
    final testFixture = await testBed.create();
    final imgElement = testFixture.rootElement.querySelector('img');
    expect(imgElement.getAttribute('alt'), 'A puppy!');
  });

  test('should render message with HTML', () async {
    final testBed = NgTestBed.forComponent(ng.TestI18nNodeWithHtmlNgFactory);
    final testFixture = await testBed.create();
    expect(testFixture.text, 'A message with emphasis!');
    final strongElement = testFixture.rootElement.querySelector('strong');
    expect(strongElement.text, 'emphasis!');
  });

  test('should render message with unsafe HTML', () async {
    final testBed =
        NgTestBed.forComponent(ng.TestI18nNodeWithUnsafeHtmlNgFactory);
    final testFixture = await testBed.create();
    expect(testFixture.text, 'Click here to file an issue.');
    final anchorElement = testFixture.rootElement.querySelector('a');
    expect(anchorElement.getAttribute('href'), issuesLink);
  });

  test('should render message with escaped Dart characters', () async {
    final testBed = NgTestBed.forComponent(
        ng.TestI18nNodeWithEscapedDartCharactersNgFactory);
    final testFixture = await testBed.create();
    expect(testFixture.text, contains('Escape\nnewline.'));
    expect(testFixture.text, contains('This is not an \$interpolation.'));
  });

  test('should render message with escaped HTML characters', () async {
    final testBed = NgTestBed.forComponent(
        ng.TestI18nNodeWithEscapedHtmlCharactersNgFactory);
    final testFixture = await testBed.create();
    expect(testFixture.text, 'Not <i>italic</i>.');
  });

  test('should render message with HTML and escaped HTML characters', () async {
    final testBed = NgTestBed.forComponent(
        ng.TestI18nNodeWithHtmlAndEscapedHtmlCharactersNgFactory);
    final testFixture = await testBed.create();
    expect(testFixture.text, 'Italic, not <i>italic</i>.');
    final italicElement = testFixture.rootElement.querySelector('i');
    expect(italicElement.text, 'Italic');
  });
}

const issuesLink = 'https://github.com/dart-lang/angular/issues';

@Component(
  selector: 'test',
  template: '<p @i18n="description">A message.</p>',
)
class TestI18nNode {}

@Component(
  selector: 'test',
  template: '<img alt="A puppy!" @i18n:alt="description">',
)
class TestI18nAttribute {}

@Component(
  selector: 'test',
  template: '''
    <p @i18n="description">
      A message with <strong>emphasis!</strong>
    </p>
  ''',
)
class TestI18nNodeWithHtml {}

@Component(
  selector: 'test',
  template: '''
    <p @i18n="description">
      Click <a href="$issuesLink">here</a> to file an issue.
    </p>
  ''',
)
class TestI18nNodeWithUnsafeHtml {}

@Component(
  selector: 'test',
  template: '''
    <p @i18n="description">Escape\nnewline.</p>
    <p @i18n="description">This is not an \$interpolation.</p>
  ''',
)
class TestI18nNodeWithEscapedDartCharacters {}

@Component(
  selector: 'test',
  template: '''
    <p @i18n="description">
      Not &lt;i&gt;italic&lt;/i&gt;.
    </p>
  ''',
)
class TestI18nNodeWithEscapedHtmlCharacters {}

@Component(
  selector: 'test',
  template: '''
    <p @i18n="description">
      <i>Italic</i>, not &lt;i&gt;italic&lt;/i&gt;.
    </p>
  ''',
)
class TestI18nNodeWithHtmlAndEscapedHtmlCharacters {}
