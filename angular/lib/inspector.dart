@JS()
library angular_inspector;

import 'package:js/js.dart';
import 'package:angular/src/devtools.dart';

const _groupName = 'inspector_internal';
var _callCount = 0;

/// Hoists functions contained in `inspector.dart` for global JS access.
///
/// Useful for manual inspections in a running application.
void hoistGlobalInspectorFunctions() {
  _activeComponents = allowInterop(() {
    return activeComponents();
  });
}

@JS(r'$activeComponents')
external set _activeComponents(Set<String> Function() func);

/// Returns a set of component names that are currently active.
///
/// Will return an empty set if devtools is not enabled.
Set<String> activeComponents() {
  var components = <String>{};
  if (isDevToolsEnabled) {
    var groupName = '$_groupName${_callCount++}';
    var nodes = Inspector.instance.getNodes(groupName);
    for (var root in nodes.toList()) {
      var queue = [root];
      while (queue.isNotEmpty) {
        var node = queue.removeAt(0);
        queue.addAll(node.children.toList());
        var component = node.component;
        if (component != null) components.add(component.name);
      }
    }
    Inspector.instance.disposeGroup(groupName);
  }
  return components;
}
