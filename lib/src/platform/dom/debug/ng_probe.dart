import "package:angular2/core.dart" show RootRenderer, NgZone, ApplicationRef;
import "package:angular2/src/core/debug/debug_node.dart"
    show DebugNode, getDebugNode;
import "package:angular2/src/core/debug/debug_renderer.dart"
    show DebugDomRootRenderer;
import "package:angular2/src/core/di.dart" show Provider;
import "package:angular2/src/facade/lang.dart" show assertionsEnabled;
import "package:angular2/src/platform/dom/dom_adapter.dart" show DOM;
import "package:angular2/src/platform/dom/dom_renderer.dart"
    show DomRootRenderer;

const CORE_TOKENS = const {"ApplicationRef": ApplicationRef, "NgZone": NgZone};
const INSPECT_GLOBAL_NAME = "ng.probe";
const CORE_TOKENS_GLOBAL_NAME = "ng.coreTokens";
/**
 * Returns a [DebugElement] for the given native DOM element, or
 * null if the given native element does not have an Angular view associated
 * with it.
 */
DebugNode inspectNativeElement(element) {
  return getDebugNode(element);
}

RootRenderer createConditionalRootRenderer(rootRenderer) {
  if (assertionsEnabled()) {
    return createRootRenderer(rootRenderer);
  }
  return rootRenderer;
}

RootRenderer createRootRenderer(rootRenderer) {
  DOM.setGlobalVar(INSPECT_GLOBAL_NAME, inspectNativeElement);
  DOM.setGlobalVar(CORE_TOKENS_GLOBAL_NAME, CORE_TOKENS);
  return new DebugDomRootRenderer(rootRenderer);
}

/**
 * Providers which support debugging Angular applications (e.g. via `ng.probe`).
 */
const List<dynamic> ELEMENT_PROBE_PROVIDERS = const [
  const Provider(RootRenderer,
      useFactory: createConditionalRootRenderer, deps: const [DomRootRenderer])
];
const List<dynamic> ELEMENT_PROBE_PROVIDERS_PROD_MODE = const [
  const Provider(RootRenderer,
      useFactory: createRootRenderer, deps: const [DomRootRenderer])
];
