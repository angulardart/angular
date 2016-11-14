import 'package:angular2/src/core/di.dart' show Injectable, Inject, OpaqueToken;
import 'package:angular2/src/core/zone/ng_zone.dart' show NgZone;
import 'package:angular2/src/facade/exceptions.dart' show BaseException;

const OpaqueToken EVENT_MANAGER_PLUGINS =
    const OpaqueToken('EventManagerPlugins');

@Injectable()
class EventManager {
  NgZone _zone;
  List<EventManagerPlugin> _plugins;
  Map<String, EventManagerPlugin> _eventToPlugin;
  EventManager(@Inject(EVENT_MANAGER_PLUGINS) List<EventManagerPlugin> plugins,
      this._zone) {
    plugins.forEach((p) => p.manager = this);
    this._plugins = plugins.reversed.toList();
    _eventToPlugin = <String, EventManagerPlugin>{};
  }
  Function addEventListener(
      dynamic element, String eventName, Function handler) {
    var plugin = this._findPluginFor(eventName);
    return plugin.addEventListener(element, eventName, handler);
  }

  NgZone getZone() {
    return this._zone;
  }

  EventManagerPlugin _findPluginFor(String eventName) {
    EventManagerPlugin plugin = _eventToPlugin[eventName];
    if (plugin != null) return plugin;
    var plugins = this._plugins;
    for (var i = 0; i < plugins.length; i++) {
      plugin = plugins[i];
      if (plugin.supports(eventName)) {
        _eventToPlugin[eventName] = plugin;
        return plugin;
      }
    }
    throw new BaseException(
        'No event manager plugin found for event ${eventName}');
  }
}

abstract class EventManagerPlugin {
  EventManager manager;

  bool supports(String eventName);

  Function addEventListener(
      dynamic element, String eventName, Function handler) {
    throw 'not implemented';
  }

  Function addGlobalEventListener(
      String element, String eventName, Function handler) {
    throw 'not implemented';
  }
}
