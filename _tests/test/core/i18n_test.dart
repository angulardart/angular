@TestOn('browser')
import 'dart:html';

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
    final imgElement =
        testFixture.rootElement.querySelector('img') as ImageElement;
    expect(imgElement.alt, 'A puppy!');
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

  // This test ensures none of our Intl.message() parameters are invalid.
  test('should render message with i18n parameters', () async {
    final testBed = NgTestBed.forComponent(ng.TestI18nParametersNgFactory);
    final testFixture = await testBed.create();
    expect(testFixture.text, 'A paragraph.');
    final imgElement = testFixture.rootElement.querySelector('img');
    expect(imgElement.getAttribute('alt'), 'An image.');
  });

  test('should render a message from a template', () async {
    final testBed = NgTestBed.forComponent(ng.TestI18nTemplateNgFactory);
    final testFixture = await testBed.create();
    expect(testFixture.text, isEmpty);
    await testFixture.update((component) {
      component.viewContainer.createEmbeddedView(component.messageTemplate);
    });
    expect(testFixture.text, 'A message in a template!');
  });

  test('should inject an i18n attribute', () async {
    final testBed = NgTestBed.forComponent(ng.TestInjectI18nAttributeNgFactory);
    final testFixture = await testBed.create();
    expect(testFixture.assertOnlyInstance.injectsMessage.message,
        'An internationalized message.');
  });

  group('should set internationalized property', () {
    test('explicitly', () async {
      final testBed = NgTestBed.forComponent(ng.TestExplicitI18nInputNgFactory);
      final testFixture = await testBed.create();
      expect(testFixture.assertOnlyInstance.greeting.message,
          'An internationalized property');
    });

    test('implicitly', () async {
      final testBed = NgTestBed.forComponent(ng.TestImplicitI18nInputNgFactory);
      final testFixture = await testBed.create();
      expect(testFixture.assertOnlyInstance.greeting.message,
          'An internationalized property');
    });
  });

  test('should support internationalized property on <template>', () async {
    final testBed = NgTestBed.forComponent(ng.TestI18nInputOnTemplateNgFactory);
    final testFixture = await testBed.create();
    expect(testFixture.assertOnlyInstance.message.message,
        'An internationalized property');
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

@Component(
  selector: 'test',
  template: '''
    <p
        @i18n="description"
        @i18n.locale="en_US"
        @i18n.meaning="meaning"
        @i18n.skip>
      A paragraph.
    </p>
    <img
        alt="An image."
        @i18n:alt="description"
        @i18n.locale:alt="en_US"
        @i18n.meaning:alt="meaning"
        @i18n.skip:alt />
  ''',
)
class TestI18nParameters {}

@Component(
  selector: 'test',
  template: '''
    <template #message @i18n="Template message description">
      A message in a <i>template</i>!
    </template>

    <div #container></div>
  ''',
)
class TestI18nTemplate {
  @ViewChild('message')
  TemplateRef messageTemplate;

  @ViewChild('container', read: ViewContainerRef)
  ViewContainerRef viewContainer;
}

@Component(
  selector: 'injects-message',
  template: '',
)
class InjectsMessage {
  final String message;

  InjectsMessage(@Attribute('message') this.message);
}

@Component(
  selector: 'test',
  template: '''
    <injects-message
        message="An internationalized message."
        @i18n:message="A description">
    </injects-message>
  ''',
  directives: [InjectsMessage],
)
class TestInjectI18nAttribute {
  @ViewChild(InjectsMessage)
  InjectsMessage injectsMessage;
}

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
  template: '''
    <greeting
        [message]="'An internationalized property'"
        @i18n:message="A description">
    </greeting>
  ''',
  directives: [GreetingComponent],
)
class TestExplicitI18nInput {
  @ViewChild(GreetingComponent)
  GreetingComponent greeting;
}

@Component(
  selector: 'test',
  template: '''
    <greeting
        message="An internationalized property"
        @i18n:message="A description">
    </greeting>
  ''',
  directives: [GreetingComponent],
)
class TestImplicitI18nInput {
  @ViewChild(GreetingComponent)
  GreetingComponent greeting;
}

@Directive(selector: '[message]')
class MessageDirective {
  MessageDirective(TemplateRef templateRef, ViewContainerRef viewContainerRef) {
    viewContainerRef.createEmbeddedView(templateRef);
  }

  @Input()
  String message;
}

@Component(
  selector: 'test',
  template: '''
    <template
        message="An internationalized property"
        @i18n:message="A description">
    </template>
  ''',
  directives: [MessageDirective],
)
class TestI18nInputOnTemplate {
  @ViewChild(MessageDirective)
  MessageDirective message;
}
