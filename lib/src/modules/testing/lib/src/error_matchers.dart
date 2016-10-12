import 'package:angular2/src/core/linker/exceptions.dart';
import 'package:matcher/matcher.dart';
import 'package:test/test.dart';

/// Returns a matcher that will match a caught exception that matches [matcher].
///
/// Unlike the normal `throws` matcher, it will automatically un-wrap internal
/// Angular exceptions and check the underlying (base) exception against
/// [matcher].
///
/// ## Example use:
///   expect(createComponent(), throwsInAngular(isStateError));
Matcher throwsInAngular(Matcher matcher) => new Throws(new _OrWrapped(matcher));

class _OrWrapped extends Matcher {
  final Matcher _typeMatcher;

  _OrWrapped(this._typeMatcher);

  @override
  Description describe(Description description) => description
      .add('Matches ')
      .addDescriptionOf(_typeMatcher)
      .add(' or an Angular exception that wraps another exception');

  @override
  bool matches(item, _) {
    return _typeMatcher.matches(
      item is ViewWrappedException ? item.originalException : item,
      _,
    );
  }
}
