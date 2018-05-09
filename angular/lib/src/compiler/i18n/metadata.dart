import 'package:angular_ast/angular_ast.dart';

const _i18nAnnotationName = 'i18n';
const _i18nAnnotationPrefix = '$_i18nAnnotationName-';

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

/// Extracts metadata from an `@i18n` annotation in [annotations].
///
/// Returns null if no valid `@i18n` annotation exists.
I18nMetadata getI18nMetadata(List<AnnotationAst> annotations) {
  for (final annotation in annotations) {
    if (annotation.name == _i18nAnnotationName) {
      final metadata = _parseI18nMetadata(annotation.value);
      if (metadata != null) {
        return metadata;
      }
    }
  }
  return null;
}

/// Extracts metadata from `@i18n-<attr>` annotations in [annotations].
///
/// Returns a map from attribute name to corresponding internationalization
/// metadata.
Map<String, I18nMetadata> getI18nAttributeMetadata(
    List<AnnotationAst> annotations) {
  final results = <String, I18nMetadata>{};
  for (final annotation in annotations) {
    if (annotation.name.startsWith(_i18nAnnotationPrefix)) {
      final name = annotation.name.substring(_i18nAnnotationPrefix.length);
      if (name.isEmpty) {
        // TODO(leonsenft): warn about missing attribute name.
        continue;
      }
      final metadata = _parseI18nMetadata(annotation.value);
      if (metadata != null) {
        results[name] = metadata;
      }
    }
  }
  return results;
}

/// Parses internationalization metadata from an annotation [value].
///
/// Grammar: [ <meaning> '|' ] <description>
///
/// Expects a description, with an optional meaning delimited by a `|`.
I18nMetadata _parseI18nMetadata(String value) {
  if (value == null) {
    // TODO(leonsenft): warn about missing annotation value.
    return null;
  }
  final index = value.indexOf('|');
  final description = value.substring(index + 1).trim();
  if (description.isEmpty) {
    // TODO(leonsenft): warn about empty description.
    return null;
  }
  if (index == -1) {
    return new I18nMetadata(description);
  }
  final meaning = value.substring(0, index).trim();
  if (meaning.isEmpty) {
    // TODO(leonsenft): warn about missing meaning with presence of '|'.
    return new I18nMetadata(description);
  }
  return new I18nMetadata(description, meaning: meaning);
}
