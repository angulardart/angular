import "package:angular2/src/core/di.dart" show Injector;
import "package:angular2/src/core/metadata/view.dart" show ViewEncapsulation;

class RenderComponentType {
  String id;
  String templateUrl;
  num slotCount;
  ViewEncapsulation encapsulation;
  List<dynamic /* String | List < dynamic > */ > styles;
  RenderComponentType(this.id, this.templateUrl, this.slotCount,
      this.encapsulation, this.styles) {}
}

abstract class RenderDebugInfo {
  Injector get injector;

  dynamic get component;

  List<dynamic> get providerTokens;

  Map<String, String> get locals;

  String get source;
}

abstract class Renderer {
  dynamic selectRootElement(
      dynamic /* String | dynamic */ selectorOrNode, RenderDebugInfo debugInfo);
  dynamic createElement(
      dynamic parentElement, String name, RenderDebugInfo debugInfo);
  dynamic createViewRoot(dynamic hostElement);
  dynamic createTemplateAnchor(
      dynamic parentElement, RenderDebugInfo debugInfo);
  dynamic createText(
      dynamic parentElement, String value, RenderDebugInfo debugInfo);
  void projectNodes(dynamic parentElement, List<dynamic> nodes);
  void attachViewAfter(dynamic node, List<dynamic> viewRootNodes);
  void detachView(List<dynamic> viewRootNodes);
  void destroyView(dynamic hostElement, List<dynamic> viewAllNodes);
  Function listen(dynamic renderElement, String name, Function callback);
  Function listenGlobal(String target, String name, Function callback);
  void setElementProperty(
      dynamic renderElement, String propertyName, dynamic propertyValue);
  void setElementAttribute(
      dynamic renderElement, String attributeName, String attributeValue);
  /**
   * Used only in debug mode to serialize property changes to dom nodes as attributes.
   */
  void setBindingDebugInfo(
      dynamic renderElement, String propertyName, String propertyValue);
  setElementClass(dynamic renderElement, String className, bool isAdd);
  setElementStyle(dynamic renderElement, String styleName, String styleValue);
  setText(dynamic renderNode, String text);
}

/**
 * Injectable service that provides a low-level interface for modifying the UI.
 *
 * Use this service to bypass Angular's templating and make custom UI changes that can't be
 * expressed declaratively. For example if you need to set a property or an attribute whose name is
 * not statically known, use [#setElementProperty] or [#setElementAttribute]
 * respectively.
 *
 * If you are implementing a custom renderer, you must implement this interface.
 *
 * The default Renderer implementation is `DomRenderer`. Also available is `WebWorkerRenderer`.
 */
abstract class RootRenderer {
  Renderer renderComponent(RenderComponentType componentType);
}
