import '../core/di.dart' show Injectable;
import '../core/security.dart';
import 'dom_sanitization_service.dart';
import 'html_sanitizer.dart';
import 'style_sanitizer.dart';
import 'url_sanitizer.dart';

// TODO(leonsenft): Temporarily export symbols that will soon be defined here.
export 'dom_sanitization_service.dart'
    show
        SafeHtmlImpl,
        SafeResourceUrlImpl,
        SafeScriptImpl,
        SafeStyleImpl,
        SafeUrlImpl;

// TODO: Remove the following lines (for --no-implicit-casts).
// ignore_for_file: argument_type_not_assignable
// ignore_for_file: invalid_assignment

@Injectable()
class DomSanitizationServiceImpl implements DomSanitizationService {
  @override
  String sanitize(TemplateSecurityContext ctx, value) {
    if (value == null) return null;
    switch (ctx) {
      case TemplateSecurityContext.none:
        // ignore: return_of_invalid_type
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
        throw new UnsupportedError(
            'unsafe value used in a resource URL context');
      default:
        throw new UnsupportedError('Unexpected SecurityContext $ctx');
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
  SafeUrl bypassSecurityTrustUrl(String value) => new SafeUrlImpl(value ?? '');

  @override
  SafeResourceUrl bypassSecurityTrustResourceUrl(String value) =>
      new SafeResourceUrlImpl(value ?? '');
}
