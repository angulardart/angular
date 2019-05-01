import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/generated/source.dart';

/// A helper to give an [AnalysisError] a "from" context [Source] and classname.
AnalysisError prefixError(
        Source fromSource, String classname, AnalysisError originalError) =>
    prefixErrorFromPath(fromSource.fullName, classname, originalError);

/// A helper to give an [AnalysisError] a "from" context path and classname.
///
/// When users have a non-standard template Url, this error message shows them
/// "In YourComponent: Error Message (from your_file.dart)" which helps users
/// understand why the error occurred.
AnalysisError prefixErrorFromPath(
    String fromSourcePath, String classname, AnalysisError originalError) {
  assert(classname != null);
  assert(classname.isNotEmpty);
  assert(fromSourcePath != null);
  assert(fromSourcePath.isNotEmpty);
  return AnalysisError.forValues(
      originalError.source,
      originalError.offset,
      originalError.length,
      originalError.errorCode,
      "In $classname: ${originalError.message} (from $fromSourcePath)",
      originalError.correction);
}
