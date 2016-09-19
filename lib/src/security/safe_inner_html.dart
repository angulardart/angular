import 'dart:html' show Element, NodeTreeSanitizer;

import 'package:angular2/angular2.dart';
import 'package:angular2/security.dart';

/// Sets [Element.innerHtml] _without_ sanitizing the HTML output.
///
/// Requires use of a [SafeHtml] wrapper created by [DomSanitizationService]:
///     var safeHtml = domSanitizationService.bypassSecurityTrustHtml('...');
///
/// (This allows security reviews to easily search for and catch exceptions)
///
/// _All_ elements are allowed, including `<script>` tags or other elements
/// that could cause cross-site scripting, unsafe URLs, and more. Only
/// **trusted** data sources should be used when using `[safeInnerHtml]`.
///
/// __Example use__:
///   @Component(
///     selector: 'my-component',
///     directives: const [SafeInnerHtmlDirective],
///     template: r'''
///       <div [safeInnerHtml]="trustedHtml"></div>
///     '''
///   )
///   class MyComponent {
///     /// WARNING: This will be embedded directly into the HTML.
///     final String trustedHtml;
///
///     MyComponent(DomSanitizationService domSecurityService)
///         : trustedHtml = domSecurityService.bypassSecurityTrustHtml(
///             'I solemnly swear that this <script></script> is OK!');
///   }
@Directive(selector: '[safeInnerHtml]')
class SafeInnerHtmlDirective {
  final Element _element;

  SafeInnerHtmlDirective(ElementRef elementRef)
      : _element = elementRef.nativeElement;

  @Input()
  set safeInnerHtml(safeInnerHtml) {
    if (safeInnerHtml is SafeHtmlImpl) {
      _element.setInnerHtml(
        safeInnerHtml.changingThisWillBypassSecurityTrust,
        treeSanitizer: NodeTreeSanitizer.trusted,
      );
    } else if (safeInnerHtml == null) {
      _element.setInnerHtml('');
    } else {
      // TODO(matanl): Should support `String` but sanitize it first.
      // i.e. using <strong>Hello World</strong> is totally fine.
      throw new UnsupportedError(
        'SafeHtml required (got ${safeInnerHtml.runtimeType})',
      );
    }
  }
}
