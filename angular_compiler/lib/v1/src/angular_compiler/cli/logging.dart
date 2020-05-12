import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
// TODO(https://github.com/dart-lang/sdk/issues/32454):
// ignore: implementation_imports
import 'package:analyzer/src/dart/element/element.dart';
import 'package:build/build.dart' as build;
import 'package:meta/meta.dart';
import 'package:source_gen/source_gen.dart';
import 'package:source_span/source_span.dart';
import 'package:stack_trace/stack_trace.dart';

import 'messages.dart';

/// Executes the provided [fn], capturing [BuildError]s and forwarding to logs.
///
/// * [showInternalTraces]: If `true`, [BuildError.stackTrace] is printed.
Future<T> runBuildZoned<T>(
  Future<T> Function() fn, {
  bool showInternalTraces = false,
  Map<Object, Object> zoneValues = const {},
}) {
  final completer = Completer<T>.sync();
  runZoned(
    () {
      fn().then((result) {
        if (!completer.isCompleted) {
          completer.complete(result);
        }
      });
    },
    onError: (e, s) {
      if (e is BuildError) {
        build.log.severe(
          e.message,
          null,
          showInternalTraces ? e.stackTrace : null,
        );
      } else if (e is UnresolvedAnnotationException) {
        final elementSpan = spanForElement(e.annotatedElement);
        final annotation = e.annotationSource.text;
        final buffer = StringBuffer()
          ..writeln(elementSpan.message('Could not resolve "$annotation"'))
          ..writeln(messages.analysisFailureReasons);
        build.log.severe(buffer, null, showInternalTraces ? s : null);
      } else {
        build.log.severe(
          'Unhandled exception in the AngularDart compiler!\n\n'
          'Please report a bug: ${messages.urlFileBugs}',
          e,
          s,
        );
      }
      if (!completer.isCompleted) {
        completer.complete();
      }
    },
    zoneSpecification: ZoneSpecification(
      print: (_, __, ___, line) => build.log.info(line),
    ),
    zoneValues: zoneValues,
  );
  return completer.future;
}

/// Creates a source span with line and column numbers.
SourceSpan sourceSpanWithLineInfo(
  int offset,
  int length,
  String source,
  Uri uri,
) {
  final sourceFile = SourceFile.fromString(source, url: uri);
  return sourceFile.span(offset, offset + length);
}

/// Base error type for all fatal errors encountered while compiling.
///
/// There is _intentionally_ not a `logFailure` function, as all failures should
/// be a result of throwing an [BuildError] or an error that extends from
/// [BuildError]. This guarantees that the build is exited as a result of the
/// failure.
class BuildError extends Error {
  /// Message describing the build error.
  final String message;

  @override
  final Trace stackTrace;

  BuildError([this.message, Trace trace])
      : stackTrace = trace ?? Trace.current();

  factory BuildError.multiple(Iterable<BuildError> errors, String message) {
    return BuildError(
        '$message:\n${errors.map((be) => be.toString()).join('\n')}');
  }

  factory BuildError.forSourceSpan(SourceSpan sourceSpan, String message,
      [Trace trace]) {
    return BuildError(sourceSpan.message(message), trace);
  }

  factory BuildError.forAnnotation(
    ElementAnnotation annotation,
    String message, [
    Trace trace,
  ]) {
    return BuildError.forSourceSpan(
        _getSourceSpanFrom(annotation), message, trace);
  }

  factory BuildError.forElement(
    Element element,
    String message, [
    Trace trace,
  ]) {
    // TODO(matanl): Once AnalysisDriver is available, revisit:
    // https://github.com/dart-lang/angular/issues/902#issuecomment-366330965
    final source = element.source;
    if (source == null || source.contents.data.isEmpty) {
      final warning = source == null
          ? 'No source text available for $element'
          : 'No source text available for $element (${source.uri})';
      logWarning('$warning: the next error may be terse');
      return BuildError(message, trace);
    }
    final sourceUrl = source.uri;
    final sourceContents = source.contents.data;
    final sourceFile = SourceFile.fromString(
      sourceContents,
      url: sourceUrl,
    );
    final sourceSpan = sourceFile.span(
      element.nameOffset,
      element.nameLength + element.nameOffset,
    );
    return BuildError.forSourceSpan(sourceSpan, message, trace);
  }

  // TODO: Remove internal API once ElementAnnotation has source information.
  // https://github.com/dart-lang/sdk/issues/32454
  static SourceSpan _getSourceSpanFrom(ElementAnnotation annotation) {
    final annotationImpl = annotation as ElementAnnotationImpl;
    final astNode = annotationImpl.annotationAst;
    return sourceSpanWithLineInfo(
      astNode.offset,
      astNode.length,
      annotation.source.contents.data,
      annotation.source.uri,
    );
  }

  /// Throws a [BuildError] caused by analyzing the provided [annotation].
  @alwaysThrows
  static dynamic throwForAnnotation(
    ElementAnnotation annotation,
    String message, [
    Trace trace,
  ]) {
    throw BuildError.forAnnotation(annotation, message, trace);
  }

  /// Throws a [BuildError] caused by analyzing the provided [element].
  @alwaysThrows
  static dynamic throwForElement(
    Element element,
    String message, [
    Trace trace,
  ]) {
    throw BuildError.forElement(element, message, trace);
  }

  @override
  String toString() => message;
}

/// Logs a fine-level [message].
///
/// Messages do not have an impact on the build, and most build systems will not
/// display by default, and need to opt-in to higher verbosity in order to see
/// the message.
///
/// These are closer to debug-only messages.
void logFine(String message) => build.log.fine(message);

/// Logs a notice-level [message].
///
/// Notices do not have an impact on the build, but most build systems will not
/// display by default, and need to opt-in to higher verbosity in order to see
/// the message.
///
/// Example messages:
/// * "Ambiguous configuration, so we assumed X"
/// * "This code is experimental"
/// * "Took XX seconds to process Y"
void logNotice(String message) => build.log.info(message);

/// Logs a warning-level [message].
///
/// Warnings do not have an impact on the build, but most build systems will
/// display them to the user, so the underlying issue should be addressable
/// (i.e. not be an "FYI"), otherwise consider using [logNotice].
///
/// Example messages:
/// * "Could not determine X, falling back to Y. Consider <...> or <...>"
/// * "This code is deprecated"
void logWarning(String message) => build.log.warning(message);

/// Throws a [BuildError] with a predefined [message].
///
/// May optionally wrap a caught stack [trace].
@alwaysThrows
void throwFailure(String message, [StackTrace trace]) {
  throw BuildError(message, trace != null ? Trace.from(trace) : null);
}
