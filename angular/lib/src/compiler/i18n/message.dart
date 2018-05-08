/// An internationalized message.
class Message {
  /// A description of this message's use.
  ///
  /// This provides translators more context to aid with translation.
  final String description;

  /// The meaning of this message, used to disambiguate equivalent messages.
  ///
  /// It's possible that two messages are textually equivalent in the source
  /// language, but have different meanings. In this case it's important that
  /// they are handled as separate translations.
  ///
  /// This value is optional, and may be null if omitted.
  final String meaning;

  /// The message text to be translated for different locales.
  final String text;

  /// Creates an internationalized message from [text] with a [description].
  ///
  /// An optional [meaning] may be included to disambiguate this message from
  /// others with equivalent text but different meaning.
  Message(
    this.text,
    this.description, {
    this.meaning,
  });
}
