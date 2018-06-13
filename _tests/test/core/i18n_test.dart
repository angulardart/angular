@TestOn('browser')
import 'package:angular/angular.dart';
import 'package:angular_test/angular_test.dart';
import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';
// Normally imported by the message files generated for each locale.
import 'package:intl/src/intl_helpers.dart';
import 'package:test/test.dart';

import 'i18n_test.template.dart' as ng;

void main() {
  tearDown(disposeAnyRunningTest);

  setUpAll(() async {
    Intl.defaultLocale = 'fr';
    // Initialize manual translations. Don't do this in production; this is a
    // shortcut to avoid dealing with file I/O in this test.
    initializeInternalMessageLookup(() => new CompositeMessageLookup());
    messageLookup.addLocale('fr', (_) => new MessageLookupForFr());
  });

  test('should render message', () async {
    final testBed =
        NgTestBed.forComponent<TestI18nNode>(ng.TestI18nNodeNgFactory);
    final testFixture = await testBed.create();
    expect(testFixture.text, 'Un message.');
  });

  test('should render message in attribute', () async {
    final testBed = NgTestBed
        .forComponent<TestI18nAttribute>(ng.TestI18nAttributeNgFactory);
    final testFixture = await testBed.create();
    final imgElement = testFixture.rootElement.querySelector('img');
    expect(imgElement.getAttribute('alt'), 'Un chiot!');
  });

  test('should render message with HTML', () async {
    final testBed = NgTestBed
        .forComponent<TestI18nNodeWithHtml>(ng.TestI18nNodeWithHtmlNgFactory);
    final testFixture = await testBed.create();
    expect(testFixture.text, 'Un message avec emphase!');
    final strongElement = testFixture.rootElement.querySelector('strong');
    expect(strongElement.text, 'emphase!');
  });

  test('should render message with unsafe HTML', () async {
    final testBed = NgTestBed.forComponent<TestI18nNodeWithUnsafeHtml>(
        ng.TestI18nNodeWithUnsafeHtmlNgFactory);
    final testFixture = await testBed.create();
    expect(testFixture.text, 'Cliquez ici pour signaler un problème.');
    final anchorElement = testFixture.rootElement.querySelector('a');
    expect(anchorElement.text, 'ici');
    expect(anchorElement.getAttribute('href'), issuesLink);
  });
}

class MessageLookupForFr extends MessageLookupByLibrary {
  @override
  String get localeName => 'fr';

  static String m0(startTag0, endTag0) =>
      'Un message avec ${startTag0}emphase!$endTag0';

  static String m1(startTag0, endTag0) =>
      'Cliquez ${startTag0}ici$endTag0 pour signaler un problème.';

  @override
  final Map<String, dynamic> messages = {
    'A message.': MessageLookupByLibrary.simpleMessage('Un message.'),
    'A puppy!': MessageLookupByLibrary.simpleMessage('Un chiot!'),
    'ViewTestI18nNodeWithHtml0_message_0': m0,
    'ViewTestI18nNodeWithUnsafeHtml0_message_0': m1,
  };
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
