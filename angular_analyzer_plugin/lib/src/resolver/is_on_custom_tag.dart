import 'package:angular_analyzer_plugin/ast.dart';

/// Custom tags shouldn't report things like unbound inputs/outputs
bool isOnCustomTag(AttributeInfo node) {
  if (node.parent == null) {
    return false;
  }

  final parent = node.parent;

  return parent is ElementInfo && parent.tagMatchedAsCustomTag;
}
