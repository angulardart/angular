import 'package:angular/src/compiler/ir/model.dart' as ir;

/// Combines multiple [ir.EventHandlers] together as an optimization.
///
/// In the case that multiple bindings on a directive or element target the same
/// event name, we can merge these handlers into a single method.
List<ir.Binding> mergeEvents(List<ir.Binding> events) {
  final _visitedEvents = <String, ir.Binding>{};
  for (var event in events) {
    var eventName = (event.target as ir.BoundEvent).name;
    var handler = _visitedEvents[eventName];
    if (handler == null) {
      _visitedEvents[eventName] = event;
      continue;
    }
    _visitedEvents[eventName] = _merge(handler, event);
  }
  return _visitedEvents.values.toList();
}

ir.Binding _merge(ir.Binding handler, ir.Binding event) => ir.Binding(
    target: handler.target,
    source: (handler.source as ir.EventHandler)
        .merge(event.source as ir.EventHandler));
