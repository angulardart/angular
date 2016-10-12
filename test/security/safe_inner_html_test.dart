@Tags(const ['codegen'])
@TestOn('browser')
library angular2.test.testing.ng_test_bed_test;

import 'package:angular2/angular2.dart';
import 'package:angular2/security.dart';
import 'package:angular2/testing_experimental.dart';
import 'package:test/test.dart';

@AngularEntrypoint()
void main() {
  tearDown(() => disposeAnyRunningTest());

  group('$SafeInnerHtmlDirective', () {
    test('normally, "innerHtml" should be sanitized', () async {
      var testBed = new NgTestBed<NormalInnerHtmlTest>();
      var testRoot = await testBed.create();
      expect(testRoot.element.text, contains('Secure'));
    });

    test('"safeInnerHtml" should be trusted', () async {
      var testBed = new NgTestBed<TrustedInnerHtmlTest>();
      var testRoot = await testBed.create();
      expect(testRoot.element.text, contains('Unsafe'));
    });

    test('unsafe HTML should throw', () async {
      var testBed = new NgTestBed<UntrustedInnerHtmlTest>();
      expect(testBed.create(), throwsInAngular(isUnsupportedError));
    });
  });
}

@Component(
  selector: 'test',
  template: r'''
       <span class="other-element">Secure</span>
       <div [innerHtml]="trustedHtml"></div>
    ''',
)
class NormalInnerHtmlTest {
  String get trustedHtml => r'''
    <script>
      document.querySelector('.other-element').innerText = 'Unsafe';
    </script>
  ''';
}

@Component(
  selector: 'test',
  directives: const [SafeInnerHtmlDirective],
  template: r'''
       <span class="other-element">Secure</span>
       <div [safeInnerHtml]="trustedHtml"></div>
    ''',
)
class TrustedInnerHtmlTest {
  /// Value will be bound directly to the DOM.
  final SafeHtml trustedHtml;

  TrustedInnerHtmlTest(DomSanitizationService domSecurityService)
      : trustedHtml = domSecurityService.bypassSecurityTrustHtml(r'''
        <script>
          document.querySelector('.other-element').innerText = 'Unsafe';
        </script>
      ''');
}

@Component(
  selector: 'test',
  directives: const [SafeInnerHtmlDirective],
  template: r'''
    <div [safeInnerHtml]="untrustedHtml"></div>
  ''',
)
class UntrustedInnerHtmlTest {
  String untrustedHtml = '<script>Bad thing</script>';
}
