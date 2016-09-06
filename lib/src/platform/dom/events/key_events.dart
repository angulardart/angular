import "dart:html";

import "package:angular2/src/core/di.dart" show Injectable;
import "package:angular2/src/core/zone/ng_zone.dart" show NgZone;
import "package:angular2/src/platform/dom/dom_adapter.dart" show DOM;

import "event_manager.dart" show EventManagerPlugin;

var modifierKeys = ["alt", "control", "meta", "shift"];
Map<String, dynamic /* (event: KeyboardEvent) => boolean */ >
    modifierKeyGetters = {
  "alt": (KeyboardEvent event) => event.altKey,
  "control": (KeyboardEvent event) => event.ctrlKey,
  "meta": (KeyboardEvent event) => event.metaKey,
  "shift": (KeyboardEvent event) => event.shiftKey
};

@Injectable()
class KeyEventsPlugin extends EventManagerPlugin {
  bool supports(String eventName) {
    return KeyEventsPlugin.parseEventName(eventName) != null;
  }

  Function addEventListener(
      dynamic element, String eventName, Function handler) {
    var parsedEvent = KeyEventsPlugin.parseEventName(eventName);
    var outsideHandler = KeyEventsPlugin.eventCallback(
        element, parsedEvent['fullKey'], handler, this.manager.getZone());
    return this.manager.getZone().runOutsideAngular(() {
      return DOM.onAndCancel(
          element, parsedEvent['domEventName'], outsideHandler);
    });
  }

  static Map<String, String> parseEventName(String eventName) {
    List<String> parts = eventName.toLowerCase().split(".");
    var domEventName = parts.removeAt(0);
    if ((identical(parts.length, 0)) ||
        !(domEventName == "keydown" || domEventName == "keyup")) {
      return null;
    }
    var key = KeyEventsPlugin._normalizeKey(parts.removeLast());
    var fullKey = "";
    modifierKeys.forEach((modifierName) {
      if (parts.remove(modifierName)) {
        fullKey += modifierName + ".";
      }
    });
    fullKey += key;
    if (parts.length != 0 || identical(key.length, 0)) {
      // returning null instead of throwing to let another plugin process the event
      return null;
    }
    return <String, String>{'domEventName': domEventName, 'fullKey': fullKey};
  }

  static String getEventFullKey(KeyboardEvent event) {
    var fullKey = "";
    var key = DOM.getEventKey(event);
    key = key.toLowerCase();
    if (key == " ") {
      key = "space";
    } else if (key == ".") {
      key = "dot";
    }
    modifierKeys.forEach((modifierName) {
      if (modifierName != key) {
        var modifierGetter = modifierKeyGetters[modifierName];
        if (modifierGetter(event)) {
          fullKey += modifierName + ".";
        }
      }
    });
    fullKey += key;
    return fullKey;
  }

  static Function eventCallback(
      dynamic element, dynamic fullKey, Function handler, NgZone zone) {
    return (event) {
      if (KeyEventsPlugin.getEventFullKey(event) == fullKey) {
        zone.runGuarded(() => handler(event));
      }
    };
  }

  /** @internal */
  static String _normalizeKey(String keyName) {
    // TODO: switch to a StringMap if the mapping grows too much
    switch (keyName) {
      case "esc":
        return "escape";
      default:
        return keyName;
    }
  }
}
