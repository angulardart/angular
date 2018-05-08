import 'package:angular_ast/angular_ast.dart';

const _i18nAnnotationName = 'i18n';
const _i18nAnnotationPrefix = '$_i18nAnnotationName-';

/// Metadata used to internationalize a message.
class Metadata {
  /// A description of an internationalized message's use.
  final String description;

  /// The meaning of an internationalized message.
  ///
  /// May be null if omitted.
  final String meaning;

  /// Creates metadata from [description] with optional [meaning].
  Metadata(
    this.description, {
    this.meaning,
  });
}

// TODO(leonsenft): handle missing description.
Metadata getTextMetadata(List<AnnotationAst> annotations) {
  for (final annotation in annotations) {
    if (annotation.name == _i18nAnnotationName) {
      return parseMetadata(annotation.value);
    }
  }
  return null;
}

// TODO(leonsenft): handle missing description.
Map<String, Metadata> getAttributeMetadata(
  List<AnnotationAst> annotations,
  ExceptionHandler exceptionHandler,
) {
  final results = <String, Metadata>{};
  for (final annotation in annotations) {
    if (annotation.name.startsWith(_i18nAnnotationPrefix)) {
      final name = annotation.name.substring(_i18nAnnotationPrefix.length);
      if (name.isEmpty) {
        // TODO(leonsenft): warn about missing attribute name.
        continue;
      }
      results[name] = parseMetadata(annotation.value);
    }
  }
  return results;
}

Metadata parseMetadata(String value) {
  final index = value.indexOf('|');
  final meaning = index > 0 ? value.substring(0, index).trim() : null;
  final description = value.substring(index + 1).trim();

  if (description.isEmpty) {
    // TODO(leonsenft): warn about missing description.
    return null;
  }

  return meaning == null || meaning.isEmpty
      ? new Metadata(description)
      : new Metadata(description, meaning: meaning);
}
