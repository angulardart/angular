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

  /// Contents of script tag.
  script,

  /// Link such as a,href.
  url,

  /// Url pointing to a resource to be loaded.
  resourceUrl,
}

/// [SanitizationService] is used by the views to sanitize values as create
/// SafeValue equivalents that can be used to bind to in templates.
abstract class SanitizationService {
  // Only used by compiler. Not tree shakeable.
  String sanitize(TemplateSecurityContext context, value);
  // Sanitizes html content.
  String sanitizeHtml(value);
  // Sanitizes css style.
  String sanitizeStyle(value);
  // Sanitizes script content.
  String sanitizeScript(value);
  // Sanitizes url link.
  String sanitizeUrl(value);
  // Sanitizes resource loading url.
  String sanitizeResourceUrl(value);
}

abstract class SafeValue {}
