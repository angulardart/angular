@TestOn('browser')

import 'dart:html';

import 'package:angular_test/angular_test.dart';
import 'package:test/test.dart';
import 'package:angular/angular.dart';
import 'package:angular/security.dart';

import 'security_integration_test.template.dart' as ng_generated;

void main() {
  ng_generated.initReflector();

  tearDown(disposeAnyRunningTest);

  test('should escape unsafe attributes', () async {
    final testBed = NgTestBed<UnsafeAttributeComponent>();
    final testFixture = await testBed.create();
    final a = testFixture.rootElement.querySelector('a') as AnchorElement;
    expect(a.href, matches(r'.*/hello$'));
    await testFixture.update((component) {
      component.href = 'javascript:alert(1)';
    });
    expect(a.href, 'unsafe:javascript:alert(1)');
  });

  test('should not escape values marked as trusted', () async {
    final testBed = NgTestBed<TrustedValueComponent>();
    final testFixture = await testBed.create();
    final a = testFixture.rootElement.querySelector('a') as AnchorElement;
    expect(a.href, 'javascript:alert(1)');
  });

  test('should throw error when using the wrong trusted value', () async {
    final testBed = NgTestBed<WrongTrustedValueComponent>();
    expect(testBed.create(), throwsA(isUnsupportedError));
  });

  test('should escape unsafe styles', () async {
    final testBed = NgTestBed<UnsafeStyleComponent>();
    final testFixture = await testBed.create();
    final div = testFixture.rootElement.querySelector('div');
    expect(div.style.background, matches('red'));
    await testFixture.update((component) {
      component.backgroundStyle = 'url(javascript:evil())';
    });
    expect(div.style.background, isNot(contains('javascript')));
  });

  test('should escape unsafe HTML', () async {
    final testBed = NgTestBed<UnsafeHtmlComponent>();
    final testFixture = await testBed.create();
    final div = testFixture.rootElement.querySelector('div');
    expect(div.innerHtml, 'some <p>text</p>');
    await testFixture.update((component) {
      component.html = 'ha <script>evil()</script>';
    });
    expect(div.innerHtml, 'ha ');
    await testFixture.update((component) {
      component.html = 'also <img src="x" onerror="evil()"> evil';
    });
    expect(div.innerHtml, 'also <img src="x"> evil');
    await testFixture.update((component) {
      component.html = 'also <iframe srcdoc="evil"> content';
    });
    expect(div.innerHtml, 'also <iframe> content</iframe>');
  });
}

@Component(
  selector: 'unsafe-attribute',
  template: '<a [href]="href">Link Title</a>',
)
class UnsafeAttributeComponent {
  String href = 'hello';
}

@Component(
  selector: 'trusted-value',
  template: '<a [href]="href">Link Title</a>',
)
class TrustedValueComponent {
  SafeUrl href;

  TrustedValueComponent(DomSanitizationService sanitizer) {
    href = sanitizer.bypassSecurityTrustUrl('javascript:alert(1)');
  }
}

@Component(
  selector: 'wrong-trusted-value',
  template: '<a [href]="href">Link Title</a>',
)
class WrongTrustedValueComponent {
  SafeHtml href;

  WrongTrustedValueComponent(DomSanitizationService sanitizer) {
    href = sanitizer.bypassSecurityTrustHtml('javascript:alert(1)');
  }
}

@Component(
  selector: 'unsafe-style',
  template: '<div [style.background]="backgroundStyle"></div>',
)
class UnsafeStyleComponent {
  String backgroundStyle = 'red';
}

@Component(
  selector: 'unsafe-html',
  template: '<div [innerHtml]="html"></div>',
)
class UnsafeHtmlComponent {
  String html = 'some <p>text</p>';
}
