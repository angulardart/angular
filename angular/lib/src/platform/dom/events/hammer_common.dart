import "event_manager.dart" show EventManagerPlugin;

var _eventNames = {
  // pan
  "pan": true,
  "panstart": true,
  "panmove": true,
  "panend": true,
  "pancancel": true,
  "panleft": true,
  "panright": true,
  "panup": true,
  "pandown": true,
  // pinch
  "pinch": true, "pinchstart": true, "pinchmove": true, "pinchend": true,
  "pinchcancel": true, "pinchin": true, "pinchout": true,
  // press
  "press": true, "pressup": true,
  // rotate
  "rotate": true, "rotatestart": true, "rotatemove": true, "rotateend": true,
  "rotatecancel": true,
  // swipe
  "swipe": true, "swipeleft": true, "swiperight": true, "swipeup": true,
  "swipedown": true,
  // tap
  "tap": true
};

class HammerGesturesPluginCommon extends EventManagerPlugin {
  HammerGesturesPluginCommon();

  bool supports(String eventName) {
    eventName = eventName.toLowerCase();
    return _eventNames.containsKey(eventName);
  }
}
