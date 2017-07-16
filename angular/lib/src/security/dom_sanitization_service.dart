import '../core/security.dart';

export '../core/security.dart';

abstract class SafeHtml extends SafeValue {}

abstract class SafeStyle extends SafeValue {}

abstract class SafeScript extends SafeValue {}

abstract class SafeUrl extends SafeValue {}

abstract class SafeResourceUrl extends SafeValue {}

/// DomSanitizationService helps preventing Cross Site Scripting Security bugs
/// (XSS) by sanitizing values to be safe to use in the different DOM contexts.
///
/// For example, when binding a URL in an `<a [href]="someUrl">` hyperlink,
/// _someUrl_ will be sanitized so that an attacker cannot inject a
/// `javascript:` URL that would execute code on the website.
///
/// In specific situations, it might be necessary to disable sanitization, for
/// example if the application genuinely needs to produce a javascript:
/// style link with a dynamic value in it.
///
/// Users can bypass security by constructing a value with one of the
/// `bypassSecurityTrust...` methods, and then binding to that value from the
/// template.
///
/// These situations should be very rare, and extraordinary care must be taken
/// to avoid creating a Cross Site Scripting (XSS) security bug!
///
/// When using `bypassSecurityTrust...`, make sure to call the method as
/// early as possible and as close as possible to the source of the value,
/// to make it easy to verify that no security bug is created by its use.
///
/// It is not required (and not recommended) to bypass security if the value
/// is safe, for example, a URL that does not start with a suspicious protocol, or an
/// HTML snippet that does not contain dangerous code. The sanitizer leaves
/// safe values intact.
abstract class DomSanitizationService implements SanitizationService {
  /// Sanitizes a value for use in the given SecurityContext.
  ///
  /// If value is trusted for the context, this method will unwrap the contained
  /// safe value and use it directly. Otherwise, value will be sanitized to be
  /// safe in the given context, for example by replacing URLs that have an
  /// unsafe protocol part (such as `javascript:`). The implementation
  /// is responsible to make sure that the value can definitely be safely used
  /// in the given context.
  String sanitize(TemplateSecurityContext context, value);

  String sanitizeHtml(value);
  String sanitizeStyle(value);
  String sanitizeScript(value);
  String sanitizeUrl(value);
  String sanitizeResourceUrl(value);

  /// Bypass security and trust the given value to be safe HTML.
  ///
  /// Only use this when the bound HTML is unsafe (e.g. contains `<script>`
  /// tags) and the code should be executed. The sanitizer will leave safe HTML
  /// intact, so in most situations this method should not be used.
  ///
  /// WARNING: calling this method with untrusted user data will cause severe
  /// security bugs!
  SafeHtml bypassSecurityTrustHtml(String value);

  /// Bypass security and trust the given value to be safe style value (CSS).
  ///
  /// WARNING: calling this method with untrusted user data will cause severe
  /// security bugs!
  SafeStyle bypassSecurityTrustStyle(String value);

  /// Bypass security and trust the given value to be safe JavaScript.
  ///
  /// WARNING: calling this method with untrusted user data will cause severe
  /// security bugs!
  SafeScript bypassSecurityTrustScript(String value);

  /// Bypass security and trust the given value to be a safe style URL, i.e. a
  /// value that can be used in hyperlinks or `<iframe src>`.
  ///
  /// WARNING: calling this method with untrusted user data will cause severe
  /// security bugs!
  SafeUrl bypassSecurityTrustUrl(String value);

  /// Bypass security and trust the given value to be a safe resource URL, i.e.
  /// a location that may be used to load executable code from, like
  /// <script src>.
  ///
  /// WARNING: calling this method with untrusted user data will cause severe
  /// security bugs!
  SafeResourceUrl bypassSecurityTrustResourceUrl(String value);
}
