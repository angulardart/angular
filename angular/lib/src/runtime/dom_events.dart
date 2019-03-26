import 'dart:html';

import 'package:angular/core.dart';

/// Provides a runtime implementation for "native" DOM events on elements.
@Injectable()
class EventManager {
  /// Plugin layers that are supported.
  static final _keyEvents = _KeyEventsHandler();

  /// Used for running with error handling [NgZone.runGuarded] in `AppView`.
  ///
  /// TODO(b/124374258): As part of soft sharding, move this elsewhere.
  final NgZone zone;

  EventManager(this.zone);

  /// Adds an event listener to [element] for [name] to invoke [callback].
  void addEventListener(
    Element element,
    String name,
    void Function(Object) callback,
  ) {
    if (_keyEvents.supports(name)) {
      // Run the actual DOM event (i.e. "keydown" or "keyup") outside of the
      // NgZone, so we can ignore change detection until the correct key(s) are
      // actually hit, then re-enter the zone.
      zone.runOutsideAngular(() {
        _keyEvents.addEventListener(element, name, callback);
      });
      return;
    }

    // If the view compiler knows that a given event is a DOM event (i.e.
    // "click"), it will never be called into EventManager. But of course the
    // browser APIs change, so this is the final fallback.
    element.addEventListener(name, callback);
  }
}

class _KeyEventsHandler {
  /// Memoized cache for parsing events.
  ///
  /// A value of `null` means the event is not supported.
  static final _cache = <String, _ParsedEvent>{};

  const _KeyEventsHandler();

  /// Returns whether the given event [name] is handled as a key event.
  bool supports(String name) {
    if (_cache.containsKey(name)) {
      return _cache[name] != null;
    }
    if (_supports(name)) {
      _cache[name] = _parse(name);
      return true;
    } else {
      _cache[name] = null;
      return false;
    }
  }

  static const _delimiter = '.';

  // This is a very basic check that technically supports invalid events.
  //
  // For example, `<input (oops.a)="...">` will return `true`, even though
  // this is not actually any event we support. We will end up dropping the
  // event (addEventListener will do nothing).
  //
  // In the future if we wanted to support other "plugin-like" events, we would
  // need a stricter check to make sure that we can actually add an event, but
  // that's unnecessary until then.
  static bool _supports(String name) => name.contains(_delimiter);

  void addEventListener(
    Element element,
    String name,
    void Function(Object) callback,
  ) {
    assert(_supports(name), 'Should never be called before "supports".');
    final parsed = _cache[name];

    // Not recognized as a valid or understood event (i.e. "oops.a").
    if (parsed == null) {
      return;
    }

    element.addEventListener(parsed.domEventName, (event) {
      if (event is KeyboardEvent && parsed.matches(event)) {
        callback(event);
      }
    });
  }

  static _ParsedEvent _parse(String name) {
    assert(_supports(name));
    final parts = name.toLowerCase().split(_delimiter);
    final domEventName = parts.removeAt(0);
    switch (domEventName) {
      case 'keydown':
      case 'keyup':
        break;
      default:
        return null;
    }
    final normalizedKey = _normalizeKey(parts.removeLast());
    final matchingKeys = _addModifiersIfAny(normalizedKey, parts);
    return _ParsedEvent(domEventName, matchingKeys);
  }

  static String _normalizeKey(String key) {
    return key == 'esc' ? 'escape' : key;
  }

  static String _addModifiersIfAny(String key, List<String> parts) {
    for (final modifier in _modifiers.keys) {
      if (parts.remove(modifier)) {
        key += '.' + modifier;
      }
    }
    return key;
  }
}

class _ParsedEvent {
  /// Actual event listened to via [Element.addEventListener].
  ///
  /// For example `'keydown'`.
  final String domEventName;

  /// Synthetic event that matches what the user may write in their template.
  ///
  /// For example `'tab.control'`.
  final String keyAndModifiers;

  const _ParsedEvent(this.domEventName, this.keyAndModifiers);

  /// Returns whether [event] matches [keyAndModifiers].
  bool matches(KeyboardEvent event) {
    final key = _keyCodeNames[event.keyCode];
    if (key == null) {
      return false;
    }
    var modifiers = '';
    for (final modifier in _modifiers.keys) {
      if (modifier != key) {
        final check = _modifiers[modifier];
        if (check(event)) {
          modifiers = '$modifiers.$modifier';
        }
      }
    }
    final fullMatch = key + modifiers;
    return fullMatch == keyAndModifiers;
  }
}

/// [KeyEvent.code] corresponding to a textual representation in the template.
const _keyCodeNames = {
  8: 'backspace',
  9: 'tab',
  12: 'clear',
  13: 'enter',
  16: 'shift',
  17: 'control',
  18: 'alt',
  19: 'pause',
  20: 'capslock',
  27: 'escape',
  32: 'space',
  33: 'pageup',
  34: 'pagedown',
  35: 'end',
  36: 'home',
  37: 'arrowleft',
  38: 'arrowup',
  39: 'arrowright',
  40: 'arrowdown',
  45: 'insert',
  46: 'delete',
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
  91: 'os',
  93: 'contextmenu',
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
  110: 'dot',
  111: '/',
  112: 'f1',
  113: 'f2',
  114: 'f3',
  115: 'f4',
  116: 'f5',
  117: 'f6',
  118: 'f7',
  119: 'f8',
  120: 'f9',
  121: 'f10',
  122: 'f11',
  123: 'f12',
  144: 'numlock',
  145: 'scrolllock'
};

/// Determines whether a given modifier key name is currently active.
final _modifiers = <String, bool Function(KeyboardEvent)>{
  'alt': (event) => event.altKey,
  'control': (event) => event.ctrlKey,
  'meta': (event) => event.metaKey,
  'shift': (event) => event.shiftKey
};
