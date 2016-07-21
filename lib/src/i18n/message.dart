import "package:angular2/src/facade/lang.dart" show isPresent, escape;

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
  var meaning = isPresent(m.meaning) ? m.meaning : "";
  var content = isPresent(m.content) ? m.content : "";
  return escape('''\$ng|${ meaning}|${ content}''');
}
