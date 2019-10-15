/// A [TemplateSecurityContext] specifies a category of security vulnerabilities
/// if the content is not sanitized.
///
/// Examples: A DOM property that is used as a url is classified as having
/// the Url [HtmlSecurityContext].
///
/// [innerHTML] that could cause Cross Site Scripting (XSS) security bugs when
/// improperly handled is classified as HTML.
///
/// See DomSanitizationService for more details on security in Angular
/// applications.
enum TemplateSecurityContext {
  /// No security implication.
  none,

  /// Context for free form html content.
  html,

  /// Context for element style.
  style,

  /// Link such as a,href.
  url,

  /// Url pointing to a resource to be loaded.
  resourceUrl,
}
