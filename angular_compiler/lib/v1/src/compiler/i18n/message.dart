import 'package:collection/collection.dart';

import 'metadata.dart';

const _map = MapEquality<String, String>();

/// An internationalized message.
class I18nMessage {
  /// Arguments that appear as interpolations in [text].
  ///
  /// These are currently only used to support HTML nested within this message.
  final Map<String, String> args;

  /// Metadata used for internationalization of this message.
  final I18nMetadata metadata;

  /// The message text to be translated for different locales.
  final String text;

  /// Creates an internationalized message from [text] with [metadata].
  ///
  /// Any arguments that appear as interpolations in [text] should be mapped
  /// to their value in [args].
  I18nMessage(
    this.text,
    this.metadata, {
    this.args = const {},
  });

  /// Whether this message contains nested HTML.
  bool get containsHtml => args.isNotEmpty;

  @override
  int get hashCode => metadata.hashCode ^ text.hashCode ^ _map.hash(args);

  @override
  bool operator ==(dynamic other) =>
      other is I18nMessage &&
      other.metadata == metadata &&
      other.text == text &&
      _map.equals(other.args, args);
}
