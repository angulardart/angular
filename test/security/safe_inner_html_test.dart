@Tags(const ['codegen'])
@TestOn('browser')
library angular2.test.testing.ng_test_bed_test;

import 'package:angular2/angular2.dart';
import 'package:angular2/security.dart';
import 'package:angular2/src/testing/test_bed/ng_test_bed.dart';
import 'package:test/test.dart';

@AngularEntrypoint()
void main() {
  group('$SafeInnerHtmlDirective', () {
    test('normally, "innerHtml" should be sanitized', () async {
      var testBed = new NgTestBed<NormalInnerHtmlTest>();
      var testRoot = await testBed.create();
      expect(testRoot.element.text, contains('Secure'));
      await testRoot.dispose();
    });

    test('"safeInnerHtml" should be trusted', () async {
      var testBed = new NgTestBed<TrustedInnerHtmlTest>();
      var testRoot = await testBed.create();
      expect(testRoot.element.text, contains('Unsafe'));
      await testRoot.dispose();
    });

    // TODO(matanl): Add a test that throws when String is used.
    // This works fine in a production app, but the NgTestBed does not surface
    // errors in a way that can be caught in a test-clause right now. Internal
    // test beds are able to do this correctly - we just need to port the code.
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
