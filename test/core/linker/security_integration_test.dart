@TestOn('browser')
library angular2.test.core.linker.security_integration_test;

import 'package:angular2/testing_internal.dart';
import 'package:angular2/src/platform/browser/browser_adapter.dart';
import 'package:angular2/src/security/dom_sanitization_service.dart';
import 'package:angular2/src/platform/dom/dom_adapter.dart' show DOM;
import 'package:angular2/core.dart' show provide, Injectable, OpaqueToken;
import 'package:angular2/src/core/metadata.dart' show Component, ViewMetadata;
import 'package:test/test.dart';

const ANCHOR_ELEMENT = const OpaqueToken('AnchorElement');

@Component(selector: 'my-comp', directives: const [])
@Injectable()
class SecuredComponent {
  dynamic ctxProp;
  SecuredComponent() {
    ctxProp = 'some value';
  }
}

main() {
  BrowserDomAdapter.makeCurrent();
  group('security integration tests', () {
    setUp(() {
      beforeEachProviders(
          () => [provide(ANCHOR_ELEMENT, useValue: el('<div></div>'))]);
    });
    group('safe HTML values', () {
      test('should disallow binding on*', () async {
        return inject([TestComponentBuilder, AsyncTestCompleter],
            (TestComponentBuilder tcb, AsyncTestCompleter completer) {
          var tpl = '<div [attr.onclick]="ctxProp"></div>';
          tcb = tcb.overrideView(
              SecuredComponent, new ViewMetadata(template: tpl));

          tcb.createAsync(SecuredComponent).catchError((e) {
            expect(
                e.message,
                contains(
                    'Binding to event attribute \'onclick\' is disallowed'));
            completer.done();
          });
        });
      });

      test('should escape unsafe attributes', () async {
        return inject([TestComponentBuilder, AsyncTestCompleter],
            (TestComponentBuilder tcb, AsyncTestCompleter completer) {
          var tpl = '<a [href]="ctxProp">Link Title</a>';
          tcb = tcb.overrideView(
              SecuredComponent, new ViewMetadata(template: tpl));
          tcb.createAsync(SecuredComponent).then((fixture) {
            var e = fixture.debugElement.children[0].nativeElement;
            fixture.debugElement.componentInstance.ctxProp = 'hello';
            fixture.detectChanges();
            // In the browser, reading href returns an absolute URL. On the
            // server side, it just echoes back the property.
            expect(e.href, matches(new RegExp('.*\/?hello\$')));
            fixture.debugElement.componentInstance.ctxProp =
                'javascript:alert(1)';
            fixture.detectChanges();
            expect(e.href, 'unsafe:javascript:alert(1)');
            completer.done();
          });
        });
      });
      test('should not escape values marked as trusted', () async {
        return inject(
            [DomSanitizationService, TestComponentBuilder, AsyncTestCompleter],
            (DomSanitizationService sanitizer, TestComponentBuilder tcb,
                AsyncTestCompleter completer) {
          var tpl = '<a [href]="ctxProp">Link Title</a>';
          tcb = tcb.overrideView(
              SecuredComponent, new ViewMetadata(template: tpl));
          tcb.createAsync(SecuredComponent).then((fixture) {
            var e = fixture.debugElement.children[0].nativeElement;
            var trusted =
                sanitizer.bypassSecurityTrustUrl('javascript:alert(1)');
            fixture.debugElement.componentInstance.ctxProp = trusted;
            fixture.detectChanges();
            expect(e.href, 'javascript:alert(1)');
            completer.done();
          });
        });
      });

      test('should error when using the wrong trusted value', () async {
        return inject(
            [DomSanitizationService, TestComponentBuilder, AsyncTestCompleter],
            (DomSanitizationService sanitizer, TestComponentBuilder tcb,
                AsyncTestCompleter completer) {
          var tpl = '<a [href]="ctxProp">Link Title</a>';
          tcb = tcb.overrideView(
              SecuredComponent, new ViewMetadata(template: tpl));
          tcb.createAsync(SecuredComponent).then((fixture) {
            var trusted =
                sanitizer.bypassSecurityTrustScript('javascript:alert(1)');
            fixture.debugElement.componentInstance.ctxProp = trusted;
            expect(() => fixture.detectChanges(), throws);
            completer.done();
          });
        });
      });

      test('should escape unsafe style values', () async {
        return inject([TestComponentBuilder, AsyncTestCompleter],
            (TestComponentBuilder tcb, AsyncTestCompleter completer) {
          var tpl = '<div [style.background]="ctxProp">Text</div>';
          tcb = tcb.overrideView(
              SecuredComponent, new ViewMetadata(template: tpl));
          tcb.createAsync(SecuredComponent).then((fixture) {
            var e = fixture.debugElement.children[0].nativeElement;
            // Make sure binding harmless values works.
            fixture.debugElement.componentInstance.ctxProp = 'red';
            fixture.detectChanges();
            // In some browsers, this will contain the full background
            // specification, not just the color.
            expect(DOM.getStyle(e, 'background'), matches(new RegExp('red.*')));
            fixture.debugElement.componentInstance.ctxProp =
                'url(javascript:evil())';
            fixture.detectChanges();
            // Updated value gets rejected, no value change.
            expect(
                DOM.getStyle(e, 'background').contains('javascript'), isFalse);
            completer.done();
          });
        });
      });

      test('should escape unsafe SVG attributes', () async {
        return inject([TestComponentBuilder, AsyncTestCompleter],
            (TestComponentBuilder tcb, AsyncTestCompleter completer) {
          var tpl = '<svg:circle [xlink:href]="ctxProp">Text</svg:circle>';
          tcb = tcb.overrideView(
              SecuredComponent, new ViewMetadata(template: tpl));
          tcb.createAsync(SecuredComponent).catchError((e) {
            expect(e.message, contains('Can\'t bind to \'xlink:href\''));
            completer.done();
          });
        });
      });

      test('should escape unsafe HTML values', () async {
        return inject([TestComponentBuilder, AsyncTestCompleter],
            (TestComponentBuilder tcb, AsyncTestCompleter completer) {
          var tpl = '<div [innerHTML]="ctxProp">Text</div>';
          tcb = tcb.overrideView(
              SecuredComponent, new ViewMetadata(template: tpl));
          tcb.createAsync(SecuredComponent).then((fixture) {
            var e = fixture.debugElement.children[0].nativeElement;
            var componentInstance = fixture.debugElement.componentInstance;
            // Make sure binding harmless values works.
            componentInstance.ctxProp = 'some <p>text</p>';
            fixture.detectChanges();
            expect(DOM.getInnerHTML(e), 'some <p>text</p>');

            componentInstance.ctxProp = 'ha <script>evil()</script>';
            fixture.detectChanges();
            expect(DOM.getInnerHTML(e), 'ha ');

            componentInstance.ctxProp = 'also <img src="x" '
                'onerror="evil()"> evil';
            fixture.detectChanges();
            expect(DOM.getInnerHTML(e), 'also <img src="x"> evil');

            componentInstance.ctxProp = 'also <iframe srcdoc="evil"> content';
            fixture.detectChanges();
            componentInstance.ctxProp = 'also <iframe> content</iframe>';
            completer.done();
          });
        });
      });
      test('should allow bypassing html', () async {
        return inject(
            [TestComponentBuilder, AsyncTestCompleter, DomSanitizationService],
            (TestComponentBuilder tcb, AsyncTestCompleter completer,
                DomSanitizationService sanitizer) {
          var tpl = '<div [innerHTML]="ctxProp">Text</div>';
          tcb = tcb.overrideView(
              SecuredComponent, new ViewMetadata(template: tpl));
          tcb.createAsync(SecuredComponent).then((fixture) {
            var e = fixture.debugElement.children[0].nativeElement;
            var componentInstance = fixture.debugElement.componentInstance;
            componentInstance.ctxProp =
                sanitizer.bypassSecurityTrustHtml('ha <script>evil()</script>');
            fixture.detectChanges();
            expect(DOM.getInnerHTML(e), 'ha <script>evil()</script>');
            completer.done();
          });
        });
      });
    });
  });
}
