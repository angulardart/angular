@Tags(const ['codegen'])
@TestOn('browser')

import 'dart:html';

import 'package:angular_test/angular_test.dart';
import 'package:test/test.dart';
import 'package:angular/angular.dart';
import 'package:angular/security.dart';

void main() {
  tearDown(disposeAnyRunningTest);

  test('should escape unsafe attributes', () async {
    final testBed = new NgTestBed<UnsafeAttributeComponent>();
    final testFixture = await testBed.create();
    final a = testFixture.rootElement.querySelector('a') as AnchorElement;
    expect(a.href, matches(r'.*/hello$'));
    await testFixture.update((component) {
      component.href = 'javascript:alert(1)';
    });
    expect(a.href, 'unsafe:javascript:alert(1)');
  });

  test('should not escape values marked as trusted', () async {
    final testBed = new NgTestBed<TrustedValueComponent>();
    final testFixture = await testBed.create();
    final a = testFixture.rootElement.querySelector('a') as AnchorElement;
    expect(a.href, 'javascript:alert(1)');
  });

  test('should throw error when using the wrong trusted value', () async {
    final testBed = new NgTestBed<WrongTrustedValueComponent>();
    expect(testBed.create(), throwsInAngular(isUnsupportedError));
  });

  test('should escape unsafe styles', () async {
    final testBed = new NgTestBed<UnsafeStyleComponent>();
    final testFixture = await testBed.create();
    final div = testFixture.rootElement.querySelector('div');
    expect(div.style.background, matches('red'));
    await testFixture.update((component) {
      component.backgroundStyle = 'url(javascript:evil())';
    });
    expect(div.style.background, isNot(contains('javascript')));
  });

  test('should escape unsafe HTML', () async {
    final testBed = new NgTestBed<UnsafeHtmlComponent>();
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
  // TODO(b/65383776): Change preserveWhitespace to false to improve codesize.
  preserveWhitespace: true,
)
class UnsafeAttributeComponent {
  String href = 'hello';
}

@Component(
  selector: 'trusted-value',
  template: '<a [href]="href">Link Title</a>',
  // TODO(b/65383776): Change preserveWhitespace to false to improve codesize.
  preserveWhitespace: true,
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
  // TODO(b/65383776): Change preserveWhitespace to false to improve codesize.
  preserveWhitespace: true,
)
class WrongTrustedValueComponent {
  SafeScript href;

  WrongTrustedValueComponent(DomSanitizationService sanitizer) {
    href = sanitizer.bypassSecurityTrustScript('javascript:alert(1)');
  }
}

@Component(
  selector: 'unsafe-style',
  template: '<div [style.background]="backgroundStyle"></div>',
  // TODO(b/65383776): Change preserveWhitespace to false to improve codesize.
  preserveWhitespace: true,
)
class UnsafeStyleComponent {
  String backgroundStyle = 'red';
}

@Component(
  selector: 'unsafe-html',
  template: '<div [innerHtml]="html"></div>',
  // TODO(b/65383776): Change preserveWhitespace to false to improve codesize.
  preserveWhitespace: true,
)
class UnsafeHtmlComponent {
  String html = 'some <p>text</p>';
}
