@TestOn('browser')
library angular2.test.testing.ng_test_bed_test;

import 'package:angular_test/angular_test.dart';
import 'package:test/test.dart';
import 'package:angular/angular.dart';
import 'package:angular/security.dart';

import 'safe_inner_html_test.template.dart' as ng_generated;

void main() {
  ng_generated.initReflector();

  tearDown(() => disposeAnyRunningTest());

  group('$SafeInnerHtmlDirective', () {
    test('normally, "innerHtml" should be sanitized', () async {
      var testBed = NgTestBed<NormalInnerHtmlTest>();
      var testRoot = await testBed.create();
      expect(testRoot.text, contains('(Secure)'));
    });

    test('"safeInnerHtml" should be trusted', () async {
      var testBed = NgTestBed<TrustedSafeInnerHtmlTest>();
      var testRoot = await testBed.create();
      expect(testRoot.text, contains('(Unsafe)'));
    });

    test('"innerHtml" should be trusted', () async {
      var testBed = NgTestBed<TrustedInnerHtmlTest>();
      var testRoot = await testBed.create();
      expect(testRoot.text, contains('(Unsafe)'));
    });

    test('normally, interpolated innerHtml should be sanitized', () async {
      var testBed = NgTestBed<InterpolatedNormalInnerHtmlTest>();
      var testRoot = await testBed.create();
      expect(testRoot.text, contains('(Secure)'));
    });

    test('SafeHtml should be passed through interpolation', () async {
      var testBed = NgTestBed<InterpolatedTrustedInnerHtmlTest>();
      var testRoot = await testBed.create();
      expect(testRoot.text, contains('(Unsafe)'));
    });

    test('unsafe HTML should throw', () async {
      var testBed = NgTestBed<UntrustedInnerHtmlTest>();
      expect(testBed.create(), throwsA(isUnsupportedError));
    });
  });
}

// <script> tags are inert in innerHTML: https://developer.mozilla.org/en-US/docs/Web/API/Element/innerHTML#Security_considerations
// placeholder from //gws/suite/img/img_test.js
const String DANGEROUS_HTML = '''
  <img src='data:image/gif;base64,R0lGODlhAQABAIAAAP///////yH5BAEKAAEALAAAAAABAAEAAAICTAEAOw=='
       onload="document.querySelector('.other-element').innerText = 'Unsafe'">
   </img>
''';

@Component(
  selector: 'test',
  template: r'''
       (<span class="other-element">Secure</span>)
       <div [innerHtml]="trustedHtml"></div>
    ''',
)
class NormalInnerHtmlTest {
  String get trustedHtml => DANGEROUS_HTML;
}

@Component(
  selector: 'test',
  directives: [SafeInnerHtmlDirective],
  template: r'''
       (<span class="other-element">Secure</span>)
       <div [safeInnerHtml]="trustedHtml"></div>
    ''',
)
class TrustedSafeInnerHtmlTest {
  /// Value will be bound directly to the DOM.
  final SafeHtml trustedHtml;

  TrustedSafeInnerHtmlTest(DomSanitizationService domSecurityService)
      : trustedHtml =
            domSecurityService.bypassSecurityTrustHtml(DANGEROUS_HTML);
}

@Component(
  selector: 'test',
  template: r'''
       (<span class="other-element">Secure</span>)
       <div [innerHtml]="trustedHtml"></div>
    ''',
)
class TrustedInnerHtmlTest {
  /// Value will be bound directly to the DOM.
  final SafeHtml trustedHtml;

  TrustedInnerHtmlTest(DomSanitizationService domSecurityService)
      : trustedHtml =
            domSecurityService.bypassSecurityTrustHtml(DANGEROUS_HTML);
}

@Component(
  selector: 'test',
  template: r'''
       (<span class="other-element">Secure</span>)
       <div innerHtml="{{trustedHtml}}"></div>
    ''',
)
class InterpolatedNormalInnerHtmlTest {
  final String trustedHtml = DANGEROUS_HTML;
}

@Component(
  selector: 'test',
  template: r'''
       (<span class="other-element">Secure</span>)
       <div innerHtml="{{trustedHtml}}"></div>
    ''',
)
class InterpolatedTrustedInnerHtmlTest {
  // Value will be passed through interpolate0 and then passed through the
  // HTML sanitizer.
  final SafeHtml trustedHtml;

  InterpolatedTrustedInnerHtmlTest(DomSanitizationService domSecurityService)
      : trustedHtml =
            domSecurityService.bypassSecurityTrustHtml(DANGEROUS_HTML);
}

@Component(
  selector: 'test',
  directives: [SafeInnerHtmlDirective],
  template: r'''
    <div [safeInnerHtml]="untrustedHtml"></div>
  ''',
)
class UntrustedInnerHtmlTest {
  String untrustedHtml = '<script>Bad thing</script>';
}
