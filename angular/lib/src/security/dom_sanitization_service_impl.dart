import 'package:angular/src/runtime.dart';

import '../core/di.dart' show Injectable;
import 'dom_sanitization_service.dart';
import 'html_sanitizer.dart';
import 'style_sanitizer.dart';
import 'url_sanitizer.dart';

@Injectable()
class DomSanitizationServiceImpl implements DomSanitizationService {
  static const _instance = DomSanitizationServiceImpl._();

  // Force a global static singleton across DDC instances for this service. In
  // angular currently it is already a single instance across all instances for
  // performance reasons. This allows a check to occur that this is really the
  // same sanitizer is used.
  factory DomSanitizationServiceImpl() => _instance;

  // Const to enforce statelessness.
  const DomSanitizationServiceImpl._();

  @override
  String sanitizeHtml(value) {
    if (value == null) return null;
    if (value is SafeHtmlImpl) return value.changingThisWillBypassSecurityTrust;
    if (value is SafeValue) {
      throw UnsupportedError(
          'Unexpected SecurityContext $value, expecting html');
    }
    return sanitizeHtmlInternal(unsafeCast(value));
  }

  @override
  String sanitizeStyle(value) {
    if (value == null) return null;
    if (value is SafeStyleImpl) {
      return value.changingThisWillBypassSecurityTrust;
    }
    if (value is SafeValue) {
      throw UnsupportedError('Unexpected SecurityContext $value, '
          'expecting style');
    }
    if (value == null) return null;
    return internalSanitizeStyle(value is String ? value : value.toString());
  }

  @override
  String sanitizeUrl(value) {
    if (value == null) return null;
    if (value is SafeUrlImpl) return value.changingThisWillBypassSecurityTrust;
    if (value is SafeValue) {
      throw UnsupportedError('Unexpected SecurityContext $value, '
          'expecting url');
    }
    return internalSanitizeUrl(value.toString());
  }

  @override
  String sanitizeResourceUrl(value) {
    if (value == null) return null;
    if (value is SafeResourceUrlImpl) {
      return value.changingThisWillBypassSecurityTrust;
    }
    if (value is SafeValue) {
      throw UnsupportedError('Unexpected SecurityContext $value, '
          'expecting resource url');
    }
    throw UnsupportedError(
        'Security violation in resource url. Create SafeValue');
  }

  @override
  SafeHtml bypassSecurityTrustHtml(String value) => SafeHtmlImpl(value ?? '');

  @override
  SafeStyle bypassSecurityTrustStyle(String value) =>
      SafeStyleImpl(value ?? '');

  @override
  SafeUrl bypassSecurityTrustUrl(String value) => SafeUrlImpl(value ?? '');

  @override
  SafeResourceUrl bypassSecurityTrustResourceUrl(String value) =>
      SafeResourceUrlImpl(value ?? '');
}

abstract class SafeValueImpl implements SafeValue {
  /// Named this way to allow security teams to
  /// to search for BypassSecurityTrust across code base.
  final String changingThisWillBypassSecurityTrust;
  SafeValueImpl(this.changingThisWillBypassSecurityTrust);

  String toString() => changingThisWillBypassSecurityTrust;
}

class SafeHtmlImpl extends SafeValueImpl implements SafeHtml {
  SafeHtmlImpl(String value) : super(value);
}

class SafeStyleImpl extends SafeValueImpl implements SafeStyle {
  SafeStyleImpl(String value) : super(value);
}

class SafeUrlImpl extends SafeValueImpl implements SafeUrl {
  SafeUrlImpl(String value) : super(value);
}

class SafeResourceUrlImpl extends SafeValueImpl implements SafeResourceUrl {
  SafeResourceUrlImpl(String value) : super(value);
}
