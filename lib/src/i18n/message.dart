/**
 * A message extracted from a template.
 *
 * The identity of a message is comprised of `content` and `meaning`.
 *
 * `description` is additional information provided to the translator.
 */
class Message {
  String content;
  String meaning;
  String description;
  Message(this.content, this.meaning, [this.description = null]) {}
}

/**
 * Computes the id of a message
 */
String id(Message m) {
  var meaning = m.meaning ?? "";
  var content = m.content ?? "";
  return Uri.encodeComponent('''\$ng|${ meaning}|${ content}''');
}
