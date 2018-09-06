import 'dart:html' show KeyboardEvent;

import 'package:angular/src/core/di.dart' show Injectable;
import 'package:angular/src/runtime.dart' show unsafeCast;

import 'event_manager.dart' show EventManagerPlugin;

final _modifierKeyGetters = <String, bool Function(KeyboardEvent)>{
  'alt': (KeyboardEvent event) => event.altKey,
  'control': (KeyboardEvent event) => event.ctrlKey,
  'meta': (KeyboardEvent event) => event.metaKey,
  'shift': (KeyboardEvent event) => event.shiftKey
};

final _keyCodeToKeyMap = const {
  8: 'Backspace',
  9: 'Tab',
  12: 'Clear',
  13: 'Enter',
  16: 'Shift',
  17: 'Control',
  18: 'Alt',
  19: 'Pause',
  20: 'CapsLock',
  27: 'Escape',
  32: ' ',
  33: 'PageUp',
  34: 'PageDown',
  35: 'End',
  36: 'Home',
  37: 'ArrowLeft',
  38: 'ArrowUp',
  39: 'ArrowRight',
  40: 'ArrowDown',
  45: 'Insert',
  46: 'Delete',
  65: 'a',
  66: 'b',
  67: 'c',
  68: 'd',
  69: 'e',
  70: 'f',
  71: 'g',
  72: 'h',
  73: 'i',
  74: 'j',
  75: 'k',
  76: 'l',
  77: 'm',
  78: 'n',
  79: 'o',
  80: 'p',
  81: 'q',
  82: 'r',
  83: 's',
  84: 't',
  85: 'u',
  86: 'v',
  87: 'w',
  88: 'x',
  89: 'y',
  90: 'z',
  91: 'OS',
  93: 'ContextMenu',
  96: '0',
  97: '1',
  98: '2',
  99: '3',
  100: '4',
  101: '5',
  102: '6',
  103: '7',
  104: '8',
  105: '9',
  106: '*',
  107: '+',
  109: '-',
  110: '.',
  111: '/',
  112: 'F1',
  113: 'F2',
  114: 'F3',
  115: 'F4',
  116: 'F5',
  117: 'F6',
  118: 'F7',
  119: 'F8',
  120: 'F9',
  121: 'F10',
  122: 'F11',
  123: 'F12',
  144: 'NumLock',
  145: 'ScrollLock'
};

@Injectable()
class KeyEventsPlugin extends EventManagerPlugin {
  @override
  bool supports(String eventName) {
    return _parseEventName(eventName) != null;
  }

  @override
  Function addEventListener(
      dynamic element, String eventName, Function handler) {
    var parsedEvent = _parseEventName(eventName);
    var outsideHandler = _eventCallback(element, parsedEvent.fullKey, handler);
    return unsafeCast(manager.zone.runOutsideAngular(() {
      return element.on[parsedEvent.domEventName].listen(outsideHandler).cancel;
    }));
  }

  static _ParsedEventName _parseEventName(String eventName) {
    List<String> parts = eventName.toLowerCase().split('.');
    var domEventName = parts.removeAt(0);
    if (parts.isEmpty ||
        !(domEventName == 'keydown' || domEventName == 'keyup')) {
      return null;
    }
    var key = _normalizeKey(parts.removeLast());
    var fullKey = '';
    for (var modifierName in _modifierKeyGetters.keys) {
      if (parts.remove(modifierName)) {
        fullKey += modifierName + '.';
      }
    }
    fullKey += key;
    if (parts.isNotEmpty || key.isEmpty) {
      // returning null instead of throwing to let another plugin process the event
      return null;
    }
    return _ParsedEventName(domEventName, fullKey);
  }

  static Function _eventCallback(
      dynamic element, String fullKey, Function handler) {
    return (event) {
      if (_getEventFullKey(event as KeyboardEvent) == fullKey) {
        handler(event);
      }
    };
  }

  static String _getEventFullKey(KeyboardEvent event) {
    var fullKey = '';
    var key = _getEventKey(event);
    key = key.toLowerCase();
    if (key == ' ') {
      key = 'space';
    } else if (key == '.') {
      key = 'dot';
    }
    for (var modifierName in _modifierKeyGetters.keys) {
      if (modifierName != key) {
        var modifierGetter = _modifierKeyGetters[modifierName];
        if (modifierGetter(event)) {
          fullKey += modifierName + '.';
        }
      }
    }
    fullKey += key;
    return fullKey;
  }

  static String _getEventKey(KeyboardEvent event) {
    int keyCode = event.keyCode;
    return _keyCodeToKeyMap.containsKey(keyCode)
        ? _keyCodeToKeyMap[keyCode]
        : 'Unidentified';
  }

  static String _normalizeKey(String keyName) {
    // TODO: switch to a StringMap if the mapping grows too much
    switch (keyName) {
      case 'esc':
        return 'escape';
      default:
        return keyName;
    }
  }
}

class _ParsedEventName {
  final String domEventName;
  final String fullKey;

  _ParsedEventName(this.domEventName, this.fullKey);
}
