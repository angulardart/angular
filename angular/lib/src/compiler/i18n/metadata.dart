import 'package:angular_ast/angular_ast.dart';

import '../template_parser.dart' show TemplateContext;

const i18nDescription = 'i18n';
const i18nDescriptionPrefix = '$i18nDescription:';
// TODO(leonsenft): remove before i18n is officially launched.
const i18nDescriptionPrefixDeprecated = '$i18nDescription-';
const i18nMeaning = 'i18nMeaning';
const i18nMeaningPrefix = '$i18nMeaning:';

const _i18nIndexForMeaning = 1;
const _i18nIndexForAttribute = 2;
final _i18nRegExp = RegExp(
    // Matches i18n prefix.
    'i18n'
    // Captures optional i18n parameter name.
    '(Meaning)?'
    // Captures attribute name, or matches end of input.
    r'(?::(.+)|$)');

/// Parses all internationalization metadata from a node's [annotations].
I18nMetadataBundle parseI18nMetadata(
  List<AnnotationAst> annotations,
  TemplateContext context,
) {
  if (annotations.isEmpty) {
    return I18nMetadataBundle.empty();
  }
  // Map metadata builders by attribute name, except for the children metadata
  // builder which has a null key.
  final builders = <String, _I18nMetadataBuilder>{};
  for (final annotation in annotations) {
    final match = _i18nRegExp.matchAsPrefix(annotation.name);
    if (match == null) {
      continue;
    }
    // If `annotation` doesn't specify an attribute name, `attribute` is null
    // which indicates this metadata internationalizes children.
    final attribute = match[_i18nIndexForAttribute];
    final builder = builders[attribute] ??= _I18nMetadataBuilder(context);
    if (match[_i18nIndexForMeaning] != null) {
      builder.meaning = annotation;
    } else {
      builder.description = annotation;
    }
  }
  final childrenMetadata = builders.remove(null)?.build();
  final attributeMetadata = <String, I18nMetadata>{};
  for (final attribute in builders.keys) {
    attributeMetadata[attribute] = builders[attribute].build();
  }
  return I18nMetadataBundle(childrenMetadata, attributeMetadata);
}

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

/// Internationalization metadata for a node's attributes and content.
class I18nMetadataBundle {
  /// Internationalization metadata for the node's attributes.
  ///
  /// Metadata is keyed by attribute name.
  final Map<String, I18nMetadata> forAttributes;

  /// Internationalization metadata for the node's children.
  ///
  /// Null if the node has no internationalized children.
  final I18nMetadata forChildren;

  I18nMetadataBundle(this.forChildren, this.forAttributes);
  I18nMetadataBundle.empty() : this(null, const {});
}

/// A builder for incrementally constructing and validating i18n metadata.
class _I18nMetadataBuilder {
  final TemplateContext _context;

  AnnotationAst description;
  AnnotationAst meaning;

  _I18nMetadataBuilder(this._context);

  I18nMetadata build() {
    if (description == null) {
      _context.reportError(
          'A corresponding message description (@i18n) is required',
          meaning.sourceSpan);
      return null;
    }
    return I18nMetadata(
      description.value.trim(),
      meaning: meaning?.value?.trim(),
    );
  }
}
