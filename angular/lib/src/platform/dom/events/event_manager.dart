import 'package:angular/src/core/di.dart' show Injectable, Inject, OpaqueToken;
import 'package:angular/src/core/zone/ng_zone.dart' show NgZone;

const OpaqueToken EVENT_MANAGER_PLUGINS = OpaqueToken('EventManagerPlugins');

@Injectable()
class EventManager {
  final NgZone zone;
  final List<EventManagerPlugin> _plugins;
  final _eventToPlugin = <String, EventManagerPlugin>{};

  EventManager(@Inject(EVENT_MANAGER_PLUGINS) this._plugins, this.zone) {
    for (int i = 0, len = _plugins.length; i < len; i++) {
      _plugins[i].manager = this;
    }
  }
  Function addEventListener(
    dynamic element,
    String eventName,
    void callback(event),
  ) {
    var plugin = _findPluginFor(eventName);
    return plugin.addEventListener(element, eventName, callback);
  }

  EventManagerPlugin _findPluginFor(String eventName) {
    EventManagerPlugin plugin = _eventToPlugin[eventName];
    if (plugin != null) return plugin;
    var plugins = _plugins;
    for (var i = plugins.length - 1; i >= 0; i--) {
      plugin = plugins[i];
      if (plugin.supports(eventName)) {
        _eventToPlugin[eventName] = plugin;
        return plugin;
      }
    }
    throw StateError('No event manager plugin found for event $eventName');
  }
}

abstract class EventManagerPlugin {
  EventManager manager;

  /// Whether this plugin should handle the event.
  bool supports(String eventName);

  /// Adds an event listener on [element] on [eventName].
  ///
  /// Calls [callback] when the event occurs.
  ///
  /// Returns a function, when called, cancels the event listener.
  Function addEventListener(
    dynamic element,
    String eventName,
    void callback(event),
  ) =>
      throw UnsupportedError('Not supported');
}
