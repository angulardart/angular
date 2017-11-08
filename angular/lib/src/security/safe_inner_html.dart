import 'dart:html' show Element, NodeTreeSanitizer;

import 'package:angular/angular.dart';
import 'package:angular/security.dart';

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

  SafeInnerHtmlDirective(this._element);

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
      // A regular string is not allowed since a security audit needs to be able
      // to search for SafeHtml and identify all locations where we are
      // bypassing sanitization. This also enforces SafeHtml usage at the
      // origin instead of passing a primitive string through layers
      // of code which could introduce mutations making security auditing
      // hard.
      throw new UnsupportedError(
        'SafeHtml required (got $safeInnerHtml)',
      );
    }
  }
}
