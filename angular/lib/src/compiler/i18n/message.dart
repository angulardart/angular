import 'metadata.dart';

/// An internationalized message.
class I18nMessage {
  /// Metadata used for internationalization of this message.
  final I18nMetadata metadata;

  /// The message text to be translated for different locales.
  final String text;

  /// Creates an internationalized message from [text] with [metadata].
  I18nMessage(this.text, this.metadata);
}
