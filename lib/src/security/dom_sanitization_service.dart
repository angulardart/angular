import '../core/di.dart' show Injectable;
import '../core/security.dart';
import 'html_sanitizer.dart';
import 'style_sanitizer.dart';
import 'url_sanitizer.dart';

export '../core/security.dart';

abstract class SafeHtml extends SafeValue {}
abstract class SafeStyle extends SafeValue {}
abstract class SafeScript extends SafeValue {}
abstract class SafeUrl extends SafeValue {}
abstract class SafeResourceUrl extends SafeValue {}

/// DomSanitizationService helps preventing Cross Site Scripting Security bugs
/// (XSS) by sanitizing values to be safe to use in the different DOM contexts.
///
/// For example, when binding a URL in an <a [href]="someValue"> hyperlink,
/// someValue will be sanitized so that an attacker cannot inject e.g. a
/// `javascript:` URL that would execute code on the website.
///
/// In specific situations, it might be necessary to disable sanitization, for
/// example if the application genuinely needs to produce a javascript:
/// style link with a dynamic value in it.
///
/// Users can bypass security by constructing a value with one of the
/// [bypassSecurityTrust...] methods, and then binding to that value from the
/// template.
///
/// These situations should be very rare, and extraordinary care must be taken
/// to avoid creating a Cross Site Scripting (XSS) security bug!
///
/// When using `bypassSecurityTrust...`, make sure to call the method as
/// early as possible and as close as possible to the source of the value,
/// to make it easy to verify no security bug is created by its use.
///
/// It is not required (and not recommended) to bypass security if the value
/// is safe, e.g. a URL that does not start with a suspicious protocol, or an
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


@Injectable()
class DomSanitizationServiceImpl implements DomSanitizationService {
  @override
  String sanitize(TemplateSecurityContext ctx, value) {
    if (value == null) return null;
    switch (ctx) {
      case TemplateSecurityContext.none:
        return value;
      case TemplateSecurityContext.html:
        if (value is SafeHtmlImpl) {
          return value.changingThisWillBypassSecurityTrust;
        }
        this._checkNotSafeValue(value, 'HTML');
        return sanitizeHtmlInternal(value.toString());
      case TemplateSecurityContext.style:
        if (value is SafeStyleImpl) {
          return value.changingThisWillBypassSecurityTrust;
        }
        this._checkNotSafeValue(value, 'Style');
        return internalSanitizeStyle(value);
      case TemplateSecurityContext.script:
        if (value is SafeScriptImpl) {
          return value.changingThisWillBypassSecurityTrust;
        }
        this._checkNotSafeValue(value, 'Script');
        throw new UnsupportedError('unsafe value used in a script context');
      case TemplateSecurityContext.url:
        if (value is SafeUrlImpl) {
          return value.changingThisWillBypassSecurityTrust;
        }
        this._checkNotSafeValue(value, 'URL');
        return internalSanitizeUrl(value.toString());
      case TemplateSecurityContext.resourceUrl:
        if (value is SafeResourceUrlImpl) {
          return value.changingThisWillBypassSecurityTrust;
        }
        this._checkNotSafeValue(value, 'ResourceURL');
        throw new UnsupportedError('unsafe value used in a resource URL context');
      default:
        throw new UnsupportedError('Unexpected SecurityContext ${ctx}');
    }
  }

  void _checkNotSafeValue(dynamic value, String expectedType) {
    if (value is SafeValueImpl) {
      throw new UnsupportedError('Required a safe $expectedType, '
          'got a ${value.getTypeName()}');
    }
  }

  @override
  String sanitizeHtml(value) {
    if (value == null) return null;
    if (value is SafeHtmlImpl) return value.changingThisWillBypassSecurityTrust;
    if (value is SafeValue)
      throw new UnsupportedError(
          'Unexpected SecurityContext $value, expecting html');
    return sanitizeHtmlInternal(value);
  }

  @override
  String sanitizeStyle(value) {
    if (value == null) return null;
    if (value is SafeStyleImpl) {
      return value.changingThisWillBypassSecurityTrust;
    }
    if (value is SafeValue)
      throw new UnsupportedError('Unexpected SecurityContext $value, '
          'expecting style');
    if (value == null) return null;
    return internalSanitizeStyle(value is String ? value : value.toString());
  }

  @override
  String sanitizeScript(value) {
    if (value == null) return null;
    if (value is SafeScriptImpl) {
      return value.changingThisWillBypassSecurityTrust;
    }
    if (value is SafeValue)
      throw new UnsupportedError(
          'Unexpected SecurityContext $value, expecting script');
    throw new UnsupportedError('Security violation in script binding.');
  }

  @override
  String sanitizeUrl(value) {
    if (value == null) return null;
    if (value is SafeUrlImpl) return value.changingThisWillBypassSecurityTrust;
    if (value is SafeValue)
      throw new UnsupportedError('Unexpected SecurityContext $value, '
          'expecting url');
    return internalSanitizeUrl(value.toString());
  }

  @override
  String sanitizeResourceUrl(value) {
    if (value == null) return null;
    if (value is SafeResourceUrlImpl) {
      return value.changingThisWillBypassSecurityTrust;
    }
    if (value is SafeValue)
      throw new UnsupportedError('Unexpected SecurityContext $value, '
          'expecting resource url');
    throw new UnsupportedError(
        'Security violation in resource url. Create SafeValue');
  }

  @override
  SafeHtml bypassSecurityTrustHtml(String value) =>
      new SafeHtmlImpl(value ?? '');

  @override
  SafeStyle bypassSecurityTrustStyle(String value) =>
      new SafeStyleImpl(value ?? '');

  @override
  SafeScript bypassSecurityTrustScript(String value) =>
      new SafeScriptImpl(value ?? '');

  @override
  SafeUrl bypassSecurityTrustUrl(String value) =>
      new SafeUrlImpl(value ?? '');

  @override
  SafeResourceUrl bypassSecurityTrustResourceUrl(String value) =>
    new SafeResourceUrlImpl(value ?? '');
}

abstract class SafeValueImpl implements SafeValue {
  /// Named this way to allow security teams to
  /// to search for BypassSecurityTrust across code base.
  final String changingThisWillBypassSecurityTrust;
  SafeValueImpl(this.changingThisWillBypassSecurityTrust);

  String getTypeName();
  String toString() => changingThisWillBypassSecurityTrust;
}

class SafeHtmlImpl extends SafeValueImpl implements SafeHtml {
  SafeHtmlImpl(String value) : super(value);
  @override
  String getTypeName() { return 'HTML'; }
}

class SafeStyleImpl extends SafeValueImpl implements SafeStyle {
  SafeStyleImpl(String value) : super(value);
  @override
  String getTypeName() { return 'Style'; }
}

class SafeScriptImpl extends SafeValueImpl implements SafeScript {
  SafeScriptImpl(String value) : super(value);
  String getTypeName() { return 'Script'; }
}

class SafeUrlImpl extends SafeValueImpl implements SafeUrl {
  SafeUrlImpl(String value) : super(value);
  String getTypeName() { return 'URL'; }
}

class SafeResourceUrlImpl extends SafeValueImpl implements SafeResourceUrl {
  SafeResourceUrlImpl(String value) : super(value);
  String getTypeName() { return 'ResourceURL'; }
}
