/// [SanitizationService] is used by the views to sanitize values as create
/// SafeValue equivalents that can be used to bind to in templates.
abstract class SanitizationService {
  // Sanitizes html content.
  String sanitizeHtml(value);
  // Sanitizes css style.
  String sanitizeStyle(value);
  // Sanitizes url link.
  String sanitizeUrl(value);
  // Sanitizes resource loading url.
  String sanitizeResourceUrl(value);
}
