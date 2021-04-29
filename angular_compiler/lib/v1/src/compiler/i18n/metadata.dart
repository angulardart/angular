import 'package:source_span/source_span.dart' show SourceSpan;
import 'package:angular_ast/angular_ast.dart';
import 'package:angular_compiler/v2/context.dart';

const i18nDescription = 'i18n';
const i18nDescriptionPrefix = '$i18nDescription:';
const i18nLocale = '$i18nDescription.locale';
const i18nLocalePrefix = '$i18nLocale:';
const i18nMeaning = '$i18nDescription.meaning';
const i18nMeaningPrefix = '$i18nMeaning:';

const _i18nIndexForLocale = 1;
const _i18nIndexForMeaning = 2;
const _i18nIndexForSkip = 3;
const _i18nIndexForAttribute = 4;
final i18nRegExp = RegExp(
    // Matches i18n prefix.
    'i18n'
    // Captures optional i18n parameter name.
    r'(?:\.(?:(locale)|(meaning)|(skip)))?'
    // Captures an attribute name following `:`, or matches end of input. This
    // intentionally matches an empty attribute name so that it may be reported
    // as an error when there's inevitably no matching attribute.
    r'(?::(.*)|$)');

/// Matches any adjacent whitespace.
final _whitespaceRegExp = RegExp(r'\s+');

/// Parses all internationalization metadata from a node's [annotations].
I18nMetadataBundle parseI18nMetadata(List<AnnotationAst> annotations) {
  if (annotations.isEmpty) {
    return I18nMetadataBundle.empty();
  }
  // Map metadata builders by attribute name, except for the children metadata
  // builder which has a null key.
  final builders = <String?, _I18nMetadataBuilder>{};
  for (final annotation in annotations) {
    final match = i18nRegExp.matchAsPrefix(annotation.name);
    if (match == null) {
      continue;
    }
    // If `annotation` doesn't specify an attribute name, `attribute` is null
    // which indicates this metadata internationalizes children.
    final attribute = match[_i18nIndexForAttribute];
    final builder = builders[attribute] ??= _I18nMetadataBuilder();
    if (match[_i18nIndexForLocale] != null) {
      builder.locale = annotation;
    } else if (match[_i18nIndexForMeaning] != null) {
      builder.meaning = annotation;
    } else if (match[_i18nIndexForSkip] != null) {
      builder.skip = annotation;
    } else {
      builder.description = annotation;
    }
  }
  final childrenMetadata = builders.remove(null)?.build();
  final attributeMetadata = <String, I18nMetadata>{};
  for (final attribute in builders.keys) {
    final metadata = builders[attribute]!.build();
    // Omit any invalid metadata.
    if (metadata != null) {
      attributeMetadata[attribute!] = metadata;
    }
  }
  return I18nMetadataBundle(childrenMetadata, attributeMetadata);
}

/// Trims [text] and collapses all adjacent whitespace to a single character.
String _normalizeWhitespace(String text) =>
    text.trim().replaceAll(_whitespaceRegExp, ' ');

/// Metadata used to internationalize a message.
class I18nMetadata {
  /// A description of a message's use.
  ///
  /// This provides translators more context to aid with translation.
  final String description;

  /// The locale code of the translation to use for this message.
  ///
  /// This overrides the locale that would otherwise be used for the
  /// translation. This is useful if translations are, or will be, available
  /// before they're allowed to be used.
  final String? locale;

  /// The meaning of a message, used to disambiguate equivalent messages.
  ///
  /// It's possible that two messages are textually equivalent in the source
  /// language, but have different meanings. In this case it's important that
  /// they are handled as separate translations.
  ///
  /// This value is optional, and may be null if omitted.
  final String? meaning;

  /// The primary source span to which this metadata is attributed.
  ///
  /// This source span may be used to later report errors related to this
  /// metadata.
  final SourceSpan origin;

  /// Whether this message should be skipped for internationalization.
  ///
  /// When true, this message is still be validated and rendered, but it isn't
  /// extracted for translation. This is useful for placeholder messages during
  /// development that haven't yet been finalized.
  final bool skip;

  /// Creates metadata from [description] with optional [meaning].
  I18nMetadata(
    this.description,
    this.origin, {
    this.locale,
    this.meaning,
    this.skip = false,
  });

  @override
  int get hashCode =>
      description.hashCode ^ locale.hashCode ^ meaning.hashCode ^ skip.hashCode;

  @override
  bool operator ==(dynamic other) =>
      other is I18nMetadata &&
      other.description == description &&
      other.locale == locale &&
      other.meaning == meaning &&
      other.skip == skip;
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
  final I18nMetadata? forChildren;

  I18nMetadataBundle(this.forChildren, this.forAttributes);
  I18nMetadataBundle.empty() : this(null, const {});
}

/// A builder for incrementally constructing and validating i18n metadata.
class _I18nMetadataBuilder {
  /// A regular expression that matches a parameter in an i18n annotation.
  ///
  /// For example, matches ".skip" in "@i18n.skip:title".
  static final _parameterRegExp = RegExp(r'\.\w+');

  AnnotationAst? description;
  AnnotationAst? locale;
  AnnotationAst? meaning;
  AnnotationAst? skip;

  /// Builds an immutable representation of the accumulated metadata.
  ///
  /// Returns null and reports an error if the metadata is incomplete or
  /// invalid.
  I18nMetadata? build() {
    if (description == null) {
      _reportMissingDescriptionFor(locale);
      _reportMissingDescriptionFor(meaning);
      _reportMissingDescriptionFor(skip);
      return null;
    }
    // Normalize values so that they're unaffected by formatting. It's
    // especially important to normalize the meaning so that formatting doesn't
    // affect the message identity. Two identical messages whose meanings are
    // formatted differently would be treated as distinct messages if the
    // whitespace wasn't normalized.
    final normalizedDescription = _normalizeWhitespace(description!.value!);
    final normalizedLocale =
        locale != null ? _normalizeWhitespace(locale!.value!) : null;
    final normalizedMeaning =
        meaning != null ? _normalizeWhitespace(meaning!.value!) : null;
    return I18nMetadata(
      normalizedDescription,
      description!.sourceSpan,
      locale: normalizedLocale,
      meaning: normalizedMeaning,
      skip: skip != null,
    );
  }

  void _reportMissingDescriptionFor(AnnotationAst? annotation) {
    if (annotation != null) {
      // Remove the parameter to create the corresponding description annotation
      // name.
      final descriptionName = annotation.name.replaceFirst(
        _parameterRegExp,
        '',
      );
      CompileContext.current.reportAndRecover(BuildError.forSourceSpan(
        annotation.sourceSpan,
        'A corresponding message description (@$descriptionName) is required',
      ));
    }
  }
}
