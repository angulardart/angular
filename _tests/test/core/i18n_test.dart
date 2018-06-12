@TestOn('browser')
import 'package:angular/angular.dart';
import 'package:angular_test/angular_test.dart';
import 'package:test/test.dart';

import 'i18n_test.template.dart' as ng;

void main() {
  tearDown(disposeAnyRunningTest);

  test('should render message', () async {
    final testBed =
        NgTestBed.forComponent<TestI18nNode>(ng.TestI18nNodeNgFactory);
    final testFixture = await testBed.create();
    expect(testFixture.text, 'A message.');
  });

  test('should render message in attribute', () async {
    final testBed = NgTestBed
        .forComponent<TestI18nAttribute>(ng.TestI18nAttributeNgFactory);
    final testFixture = await testBed.create();
    final imgElement = testFixture.rootElement.querySelector('img');
    expect(imgElement.getAttribute('alt'), 'A puppy!');
  });

  test('should render message with HTML', () async {
    final testBed = NgTestBed
        .forComponent<TestI18nNodeWithHtml>(ng.TestI18nNodeWithHtmlNgFactory);
    final testFixture = await testBed.create();
    expect(testFixture.text, 'A message with emphasis!');
    final strongElement = testFixture.rootElement.querySelector('strong');
    expect(strongElement.text, 'emphasis!');
  });

  test('should render message with unsafe HTML', () async {
    final testBed = NgTestBed.forComponent<TestI18nNodeWithUnsafeHtml>(
        ng.TestI18nNodeWithUnsafeHtmlNgFactory);
    final testFixture = await testBed.create();
    expect(testFixture.text, 'Click here to file an issue.');
    final anchorElement = testFixture.rootElement.querySelector('a');
    expect(anchorElement.getAttribute('href'), issuesLink);
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
  template: '<img alt="A puppy!" @i18n-alt="description">',
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
