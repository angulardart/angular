import 'package:angular_ast/angular_ast.dart';

import '../parse_util.dart' show ParseErrorLevel;
import '../template_parser.dart' show TemplateContext;

const i18nAnnotationName = 'i18n';
const i18nAnnotationPrefix = '$i18nAnnotationName-';

/// Metadata used to internationalize a message.
class I18nMetadata {
  /// A description of a message's use.
  ///
  /// This provides translators more context to aid with translation.
  final String description;

  /// The meaning of a message, used to disambiguate equivalent messages.
  ///
  /// It's possible that two messages are textually equivalent in the source
  /// language, but have different meanings. In this case it's important that
  /// they are handled as separate translations.
  ///
  /// This value is optional, and may be null if omitted.
  final String meaning;

  /// Creates metadata from [description] with optional [meaning].
  I18nMetadata(
    this.description, {
    this.meaning,
  });
}

/// Returns the first `@i18n` annotation in [annotations], or null.
AnnotationAst i18nAnnotationFrom(List<AnnotationAst> annotations) {
  for (final annotation in annotations) {
    if (annotation.name == i18nAnnotationName) {
      return annotation;
    }
  }
  return null;
}

/// Returns all `@i18n-<attr>` annotations in [annotations] by attribute name.
Map<String, AnnotationAst> i18nAttributeAnnotationsFrom(
  List<AnnotationAst> annotations,
) {
  final results = <String, AnnotationAst>{};
  for (final annotation in annotations) {
    if (annotation.name.startsWith(i18nAnnotationPrefix)) {
      final name = annotation.name.substring(i18nAnnotationPrefix.length);
      results[name] = annotation;
    }
  }
  return results;
}

/// Parses internationalization metadata from an [annotation].
///
/// Grammar: [ <meaning> '|' ] <description>
///
/// Expects a description, with an optional meaning delimited by a `|`.
I18nMetadata parseI18nMetadata(
  AnnotationAst annotation,
  TemplateContext context,
) {
  final value = annotation.value;
  final index = value.indexOf('|');
  final description = value.substring(index + 1).trim();
  if (description.isEmpty) {
    context.reportError(
      'Requires a non-empty message description to help translators',
      annotation.sourceSpan,
    );
    return null;
  }
  if (index == -1) {
    return I18nMetadata(description);
  }
  final meaning = value.substring(0, index).trim();
  if (meaning.isEmpty) {
    context.reportError(
      'Expected a non-empty message meaning before "|"',
      annotation.sourceSpan,
      ParseErrorLevel.WARNING,
    );
    return I18nMetadata(description);
  }
  return I18nMetadata(description, meaning: meaning);
}
