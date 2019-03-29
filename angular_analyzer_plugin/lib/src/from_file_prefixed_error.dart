import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/generated/source.dart';

/// A wrapper around [AnalysisError] which links to a "from" file and classname.
///
/// When users have a non-standard template Url, this error message shows them
/// "In YourComponent: Error Message (from your_file.dart)" which helps users
/// understand why the error occurred.
///
/// This is a wrapper, not just an extension, so that it can have a different
/// [hashCode] and operator`==` than the error without a "from" path. Template
/// files are used in two contexts (ie, from a prod & test component), and we
/// want to make sure the errors are not equal across those contexts.
class FromFilePrefixedError implements AnalysisError {
  final String fromSourcePath;
  final String classname;
  final AnalysisError originalError;
  String _message;

  FromFilePrefixedError(
      Source fromSource, String classname, AnalysisError originalError)
      : this.fromPath(fromSource.fullName, classname, originalError);

  FromFilePrefixedError.fromPath(
      this.fromSourcePath, this.classname, AnalysisError originalError)
      : originalError = originalError,
        assert(classname != null),
        assert(classname.isNotEmpty),
        assert(fromSourcePath != null),
        assert(fromSourcePath.isNotEmpty) {
    _message = "In $classname: ${originalError.message} (from $fromSourcePath)";
  }

  @override
  String get correction => originalError.correction;

  @override
  ErrorCode get errorCode => originalError.errorCode;

  @override
  int get hashCode {
    var hashCode = offset;
    hashCode ^= (_message != null) ? _message.hashCode : 0;
    hashCode ^= (source != null) ? source.hashCode : 0;
    return hashCode;
  }

  @override
  bool get isStaticOnly => originalError.isStaticOnly;

  @override
  set isStaticOnly(bool v) => originalError.isStaticOnly = v;

  @override
  int get length => originalError.length;

  @override
  set length(int v) => originalError.length = v;

  @override
  String get message => _message;

  @override
  int get offset => originalError.offset;

  @override
  set offset(int v) => originalError.offset = v;

  @override
  Source get source => originalError.source;

  @override
  bool operator ==(Object other) =>
      other is FromFilePrefixedError &&
      other.originalError == originalError &&
      other._message == message;
}
