import 'dart:html';
import 'dart:js' as js;

import "package:angular/src/core/di.dart" show Injectable, Inject, OpaqueToken;
import 'package:angular/src/facade/exceptions.dart' show BaseException;

import './hammer_common.dart';

const OpaqueToken HAMMER_GESTURE_CONFIG =
    const OpaqueToken("HammerGestureConfig");

void overrideDefault(js.JsObject mc, String eventName, Object config) {
  var jsObj = mc.callMethod('get', [eventName]);
  jsObj.callMethod('set', [new js.JsObject.jsify(config)]);
}

@Injectable()
class HammerGestureConfig {
  List<String> events = [];
  Map overrides = {};

  js.JsObject buildHammer(Element element) {
    var mc = new js.JsObject(js.context['Hammer'], [element]);
    overrideDefault(mc, 'pinch', {'enable': true});
    overrideDefault(mc, 'rotate', {'enable': true});
    this.overrides.forEach((Object config, String eventName) =>
        overrideDefault(mc, eventName, config));
    return mc;
  }
}

@Injectable()
class HammerGesturesPlugin extends HammerGesturesPluginCommon {
  final HammerGestureConfig _config;

  HammerGesturesPlugin(@Inject(HAMMER_GESTURE_CONFIG) this._config);

  @override
  bool supports(String eventName) {
    if (!super.supports(eventName) && !this.isCustomEvent(eventName))
      return false;

    if (!js.context.hasProperty('Hammer')) {
      throw new BaseException(
          'Hammer.js is not loaded, can not bind $eventName event');
    }

    return true;
  }

  @override
  Function addEventListener(el, String eventName, Function handler) {
    Element element = el;
    var zone = manager.getZone();
    var subscription;
    eventName = eventName.toLowerCase();

    zone.runOutsideAngular(() {
      // Creating the manager bind events, must be done outside of angular
      var mc = this._config.buildHammer(element);

      subscription = mc.callMethod('on', [
        eventName,
        (eventObj) {
          var dartEvent = new HammerEvent._fromJsEvent(eventObj);
          handler(dartEvent);
        }
      ]);
    });
    return () => subscription?.cancel();
  }

  bool isCustomEvent(String eventName) {
    return this._config.events.indexOf(eventName) > -1;
  }
}

class HammerEvent {
  num angle;
  num centerX;
  num centerY;
  int deltaTime;
  int deltaX;
  int deltaY;
  int direction;
  num distance;
  num rotation;
  num scale;
  Node target;
  int timeStamp;
  String type;
  num velocity;
  num velocityX;
  num velocityY;
  js.JsObject jsEvent;

  HammerEvent._fromJsEvent(js.JsObject event) {
    angle = event['angle'];
    var center = event['center'];
    centerX = center['x'];
    centerY = center['y'];
    deltaTime = event['deltaTime'];
    deltaX = event['deltaX'];
    deltaY = event['deltaY'];
    direction = event['direction'];
    distance = event['distance'];
    rotation = event['rotation'];
    scale = event['scale'];
    target = event['target'];
    timeStamp = event['timeStamp'];
    type = event['type'];
    velocity = event['velocity'];
    velocityX = event['velocityX'];
    velocityY = event['velocityY'];
    jsEvent = event;
  }
}
