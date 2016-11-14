part of angular2_template_parser.src.lexer;

/// Type of [NgToken].
enum NgTokenType {
  /// Parsed text.
  textNode,

  /// <!-- before comment
  beginComment,

  /// Parsed comment.
  commentNode,

  /// --> after comment
  endComment,

  /// Parsed interpolated expression.
  interplateNode,

  /// Before parsing the [elementName].
  startOpenElement,

  /// After parsing the [elementName].
  endOpenElement,

  /// After parsing an [endOpenElement] that does not have content.
  endVoidElement,

  /// Parsed element name.
  elementName,

  /// After parsing an element tag and child nodes.
  startCloseElement,

  /// After parsing an element.
  endCloseElement,

  /// Before the start of an attribute, event, or property (i.e. whitespace).
  beforeElementDecorator,

  /// Before parsing a decorator value.
  beforeDecoratorValue,

  /// Parsed attribute name.
  attributeName,

  /// Parsed attribute value.
  attributeValue,

  /// After parsing an [attributeName], and optionally, [attributeValue].
  endAttribute,

  /// Before parsing a [propertyName].
  startProperty,

  /// Parsed property name.
  propertyName,

  /// Parsed property value.
  propertyValue,

  /// After parsing a [propertyName], and optionally, [propertyValue].
  endProperty,

  /// Before parsing an [eventName].
  startEvent,

  /// Parsed event name.
  eventName,

  /// Parsed event value.
  eventValue,

  /// After parsing an [eventName] and [eventValue].
  endEvent,

  /// Before parsing a binding.
  startBinding,

  /// Binding name.
  bindingName,

  /// Binding value (optional).
  bindingValue,

  /// after parsing a binding, should be empty.
  endBinding,

  /// Before parsing a banana (in a box).
  startBanana,

  /// The name of the banana (in a box).
  bananaName,

  /// The banana value.
  bananaValue,

  /// After parsing a [bananaName] and [bananaValue].
  endBanana,

  /// An unexpected or invalid token.
  ///
  /// In a stricter mode, this should cause the parsing to fail. It can also be
  /// ignored in order to attempt to produce valid output - for example a user
  /// may want to still validate the rest of the (seemingly valid) template
  /// even if there is an error somewhere at the beginning.
  errorToken,
}
