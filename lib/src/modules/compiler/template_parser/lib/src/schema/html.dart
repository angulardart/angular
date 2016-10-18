import '../schema.dart';

const _$mouse = const NgTypeReference.dartSdk('html', 'MouseEvent');
const _$string = const NgTypeReference.dartSdk('core', 'String');

/// Represents the native DOM HTML5 schema.
///
/// **WARNING**: This is an incomplete schema, and should be auto-generated.
const html5Schema = const NgTemplateSchema(const {
  'div': const NgElementSchema(
    'div',
    events: const {
      'click': const NgEventDefinition('click', _$mouse),
    },
    properties: const {
      'title': const NgPropertyDefinition('title', _$string),
    },
  ),
  'span': const NgElementSchema(
    'span',
    events: const {
      'click': const NgEventDefinition('click', _$mouse),
    },
    properties: const {
      'title': const NgPropertyDefinition('title', _$string),
    },
  ),
});
