/// A base class for the WrappedException that can be used to identify
/// a WrappedException from ExceptionHandler without adding circular
/// dependency.
class BaseWrappedException extends Error {
  BaseWrappedException();

  dynamic get originalException => null;
  StackTrace get originalStack => null;

  String get message => '';
  String get wrapperMessage => '';
  dynamic get context => null;
}
