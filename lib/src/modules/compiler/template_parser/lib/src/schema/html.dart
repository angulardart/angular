import '../schema.dart';

/// Event Types
const _eventMouse = const NgTypeReference.dartSdk('html', 'MouseEvent');
const _eventKeyboard = const NgTypeReference.dartSdk('html', 'KeyboardEvent');
const _eventInput = const NgTypeReference.dartSdk('html', 'InputEvent');

/// Types
const _typeString = const NgTypeReference.dartSdk('core', 'String');
const _typeBool = const NgTypeReference.dartSdk('core', 'bool');
const _typeInt = const NgTypeReference.dartSdk('core', 'int');

/// Global
/// src: https://developer.mozilla.org/en-US/docs/Web/Events
/// does not include all events, for now.
const _globalEvents = const {
  // mouse events.
  'mouseEnter': const NgEventDefinition('mouseenter', _eventMouse),
  'mouseOver': const NgEventDefinition('mouseover', _eventMouse),
  'mouseMove': const NgEventDefinition('mousemove', _eventMouse),
  'mouseDown': const NgEventDefinition('mousedown', _eventMouse),
  'mouseUp': const NgEventDefinition('mouseup', _eventMouse),
  'click': const NgEventDefinition('click', _eventMouse),
  'dblClick': const NgEventDefinition('dblclick', _eventMouse),
  //'contextMenu': const NgEventDefinition('contextmenu', _eventMouse),
  'wheel': const NgEventDefinition('wheel', _eventMouse),
  'mouseLeave': const NgEventDefinition('mouseleave', _eventMouse),
  'mouseOut': const NgEventDefinition('mouseout', _eventMouse),
  'select': const NgEventDefinition('select', _eventMouse),
  'pointerLockChange':
      const NgEventDefinition('pointerlockchange', _eventMouse),
  'pointerLockError': const NgEventDefinition('pointerLockError', _eventMouse),
  // keyboard events.
  'keyDown': const NgEventDefinition('keydown', _eventKeyboard),
  'keyPress': const NgEventDefinition('keypress', _eventKeyboard),
  'keyUp': const NgEventDefinition('keyup', _eventKeyboard)
};

/// Global attributes are availible on every node, even those not
/// defined by html.
///
/// src: https://developer.mozilla.org/en-US/docs/Web/HTML/Global_attributes
const _globalProperties = const {
  'accesskey': const NgPropertyDefinition('accesskey', _typeString),
  'class': const NgPropertyDefinition('class', _typeString),
  'contenteditable': const NgPropertyDefinition('contenteditable', _typeBool),
  //'contentmenu': const NgPropertyDefinition('contentmenu', _typeString),
  'data-*': const NgPropertyDefinition('data-*', _typeString),
  'dir': const NgPropertyDefinition('dir', _typeString),
  'hidden': const NgPropertyDefinition('hidden', _typeString),
  'id': const NgPropertyDefinition('id', _typeString),
  'lang': const NgPropertyDefinition('lang', _typeString),
  'style': const NgPropertyDefinition('style', _typeString),
  'tabindex': const NgPropertyDefinition('tabindex', _typeInt),
  'title': const NgPropertyDefinition('title', _typeString),
  'translate': const NgPropertyDefinition('translate', _typeString),
};

/// Represents the native DOM HTML5 schema.
///
/// **WARNING**: This is an incomplete schema, and should be auto-generated.
/// Could we somehow use something like .oneOf(['off', 'on', ..]);
const html5Schema = const NgTemplateSchema(const {
  'div': const NgElementDefinition(
    'div',
    events: const {},
    properties: const {
      'title': const NgPropertyDefinition('title', _typeString),
    },
    globalEvents: _globalEvents,
    globalProperties: _globalProperties,
  ),
  'span': const NgElementDefinition(
    'span',
    events: const {},
    properties: const {
      'title': const NgPropertyDefinition('title', _typeString),
    },
    globalEvents: _globalEvents,
    globalProperties: _globalProperties,
  ),
  // src: https://developer.mozilla.org/en-US/docs/Web/HTML/Element/input
  'input': const NgElementDefinition(
    'input',
    events: const {
      'input': const NgEventDefinition('input', _eventInput),
      'change': const NgEventDefinition('change', _eventInput),
    },
    properties: const {
      'type': const NgPropertyDefinition('type', _typeString),
      'accept': const NgPropertyDefinition('accept', _typeString),
      'autocomplete': const NgPropertyDefinition('autocomplete', _typeString),
      'autofocus': const NgPropertyDefinition('autofocus', _typeString),
      'capture': const NgPropertyDefinition('capture', _typeString),
      'checked': const NgPropertyDefinition('checked', _typeString),
      'disabled': const NgPropertyDefinition('disabled', _typeString),
      'form': const NgPropertyDefinition('form', _typeString),
      'formaction': const NgPropertyDefinition('formaction', _typeString),
      'formmethod': const NgPropertyDefinition('formmethod', _typeString),
      'formvalidate': const NgPropertyDefinition('formvalidate', _typeString),
      'formtarget': const NgPropertyDefinition('formtarget', _typeString),
      'height': const NgPropertyDefinition('height', _typeString),
      'inputmode': const NgPropertyDefinition('inputmode', _typeString),
      'list': const NgPropertyDefinition('list', _typeString),
      'max': const NgPropertyDefinition('max', _typeString),
      'maxlength': const NgPropertyDefinition('maxlength', _typeString),
      'min': const NgPropertyDefinition('min', _typeString),
      'minlength': const NgPropertyDefinition('minLength', _typeString),
      'multiple': const NgPropertyDefinition('multiple', _typeString),
      'name': const NgPropertyDefinition('name', _typeString),
      'pattern': const NgPropertyDefinition('pattern', _typeString),
      'placeholder': const NgPropertyDefinition('placeholder', _typeString),
      'readonly': const NgPropertyDefinition('readonly', _typeString),
      'required': const NgPropertyDefinition('required', _typeString),
      'selectiondirection':
          const NgPropertyDefinition('selectiondirection', _typeString),
      'selectionend': const NgPropertyDefinition('selectionend', _typeString),
      'selectionstart':
          const NgPropertyDefinition('selectionstart', _typeString),
      'size': const NgPropertyDefinition('size', _typeString),
      'spellcheck': const NgPropertyDefinition('spellcheck', _typeString),
      'src': const NgPropertyDefinition('src', _typeString),
      'step': const NgPropertyDefinition('step', _typeString),
      'value': const NgPropertyDefinition('value', _typeString),
      'width': const NgPropertyDefinition('width', _typeString),
    },
    globalEvents: _globalEvents,
    globalProperties: _globalProperties,
  ),
  'button': const NgElementDefinition(
    'button',
    events: const {},
    properties: const {
      'autofocus': const NgPropertyDefinition('autofocus', _typeString),
      'disabled': const NgPropertyDefinition('disabled', _typeBool),
      'form': const NgPropertyDefinition('form', _typeString),
      'formaction': const NgPropertyDefinition('formaction', _typeString),
      'formenctype': const NgPropertyDefinition('formenctype', _typeString),
      'formmethod': const NgPropertyDefinition('formmethod', _typeString),
      'formnovalidate':
          const NgPropertyDefinition('formnovalidate', _typeString),
      'formtarget': const NgPropertyDefinition('formtarget', _typeString),
      'name': const NgPropertyDefinition('name', _typeString),
      'type': const NgPropertyDefinition('type', _typeString),
      'value': const NgPropertyDefinition('value', _typeString),
    },
    globalEvents: _globalEvents,
    globalProperties: _globalProperties,
  )
});
