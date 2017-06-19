import 'dart:html';

import "debug_node.dart";

/// Predicates for use with [DebugElement]'s query functions.
class By {
  /// Match all elements.
  static Predicate<DebugElement> all() => (debugElement) => true;

  /// Match elements by the given CSS selector.
  static Predicate<DebugElement> css(String selector) {
    return (debugElement) {
      Node node = debugElement.nativeElement;
      return (node is Element && node.matches(selector));
    };
  }

  /// Match elements that have the given directive present.
  static Predicate<DebugElement> directive(Type type) {
    return (debugElement) {
      return !identical(debugElement.providerTokens.indexOf(type), -1);
    };
  }

  /// Match elements that have the given directive present.
  static Predicate<DebugNode> nodeDirective(Type type) {
    return (debugNode) {
      return !identical(debugNode.providerTokens.indexOf(type), -1);
    };
  }
}
