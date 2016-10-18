import '../schema.dart';

const _eventMouse = const NgTypeReference.dartSdk('html', 'MouseEvent');
const _typeString = const NgTypeReference.dartSdk('core', 'String');

/// Represents the native DOM HTML5 schema.
///
/// **WARNING**: This is an incomplete schema, and should be auto-generated.
const html5Schema = const NgTemplateSchema(const {
  'div': const NgElementDefinition(
    'div',
    events: const {
      'click': const NgEventDefinition('click', _eventMouse),
    },
    properties: const {
      'title': const NgPropertyDefinition('title', _typeString),
    },
  ),
  'span': const NgElementDefinition(
    'span',
    events: const {
      'click': const NgEventDefinition('click', _eventMouse),
    },
    properties: const {
      'title': const NgPropertyDefinition('title', _typeString),
    },
  ),
});
