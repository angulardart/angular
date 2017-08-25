import "compile_metadata.dart"
    show CompileIdentifierMetadata, CompileTokenMetadata;

final APP_VIEW_MODULE_URL = "asset:angular/lib/src/core/linker/app_view.dart";
final DEBUG_APP_VIEW_MODULE_URL =
    "asset:angular/lib/src/debug/debug_app_view.dart";
final APP_VIEW_UTILS_MODULE_URL =
    "asset:angular/lib/src/core/linker/app_view_utils.dart";
final CD_MODULE_URL =
    "asset:angular/lib/src/core/change_detection/change_detection.dart";
final ANGULAR_ROOT_URL = "package:angular/angular.dart";
final NG_IF_URL = "asset:angular/lib/src/common/directives/ng_if.dart";
final NG_FOR_URL = "asset:angular/lib/src/common/directives/ng_for.dart";
final PROFILE_RUNTIME_MODULE_URL =
    "asset:angular/lib/src/debug/profile_runtime.dart";

class Identifiers {
  static final appViewUtils = new CompileIdentifierMetadata<dynamic>(
      name: "appViewUtils", moduleUrl: APP_VIEW_UTILS_MODULE_URL);
  static final ngAnchor = new CompileIdentifierMetadata<dynamic>(
      name: 'ngAnchor', moduleUrl: APP_VIEW_MODULE_URL);
  static final AppView = new CompileIdentifierMetadata<dynamic>(
      name: "AppView", moduleUrl: APP_VIEW_MODULE_URL);
  static final DebugAppView = new CompileIdentifierMetadata<dynamic>(
      name: "DebugAppView", moduleUrl: DEBUG_APP_VIEW_MODULE_URL);
  static final ViewContainer = new CompileIdentifierMetadata<dynamic>(
      name: "ViewContainer",
      moduleUrl: "asset:angular/lib/src/core/linker/view_container.dart");
  static final ElementRef = new CompileIdentifierMetadata<dynamic>(
      name: "ElementRef",
      moduleUrl: "asset:angular/lib/src/core/linker/element_ref.dart");
  static final ElementRefToken = identifierToken(ElementRef);
  static final ViewContainerRef = new CompileIdentifierMetadata<dynamic>(
      name: "ViewContainerRef",
      moduleUrl: "asset:angular/lib/src/core/linker/view_container_ref.dart");
  static final ViewContainerRefToken =
      identifierToken(Identifiers.ViewContainerRef);
  static final ComponentLoader = new CompileIdentifierMetadata<dynamic>(
      name: "ComponentLoader",
      moduleUrl: "asset:angular/lib/src/core/linker/component_loader.dart");
  static final ComponentLoaderToken = identifierToken(ComponentLoader);
  static final ChangeDetectorRef = new CompileIdentifierMetadata<dynamic>(
      name: "ChangeDetectorRef",
      moduleUrl: 'asset:angular/lib/src/core/change_detection/'
          'change_detector_ref.dart');
  static final ChangeDetectorRefToken =
      identifierToken(Identifiers.ChangeDetectorRef);
  static final ComponentFactory = new CompileIdentifierMetadata<dynamic>(
      name: 'ComponentFactory', moduleUrl: ANGULAR_ROOT_URL);
  static final DirectiveChangeDetector = new CompileIdentifierMetadata<dynamic>(
      name: 'DirectiveChangeDetector',
      moduleUrl: 'asset:angular/lib/src/core/'
          'change_detection/directive_change_detector.dart');
  static final RenderComponentType = new CompileIdentifierMetadata<dynamic>(
      name: "RenderComponentType",
      moduleUrl: "asset:angular/lib/src/core/render/api.dart");
  static final ComponentRef = new CompileIdentifierMetadata<dynamic>(
      name: "ComponentRef", moduleUrl: ANGULAR_ROOT_URL);
  static final QueryList = new CompileIdentifierMetadata<dynamic>(
      name: "QueryList",
      moduleUrl: "asset:angular/lib/src/core/linker/query_list.dart");
  static final TemplateRef = new CompileIdentifierMetadata<dynamic>(
      name: "TemplateRef",
      moduleUrl: "asset:angular/lib/src/core/linker/template_ref.dart");
  static final TemplateRefToken = identifierToken(Identifiers.TemplateRef);
  static final ValueUnwrapper = new CompileIdentifierMetadata<dynamic>(
      name: "ValueUnwrapper", moduleUrl: CD_MODULE_URL);
  static final Injector = new CompileIdentifierMetadata<dynamic>(
      name: "Injector",
      moduleUrl: 'asset:angular/lib/src/di/injector/injector.dart');
  static final InjectorToken = identifierToken(Identifiers.Injector);
  static final ViewEncapsulation = new CompileIdentifierMetadata<dynamic>(
      name: "ViewEncapsulation", moduleUrl: ANGULAR_ROOT_URL);
  static final ViewType = new CompileIdentifierMetadata<dynamic>(
      name: "ViewType",
      moduleUrl: 'asset:angular/lib/src/core/linker/view_type.dart');
  static final ChangeDetectionStrategy = new CompileIdentifierMetadata<dynamic>(
      name: "ChangeDetectionStrategy", moduleUrl: CD_MODULE_URL);
  static final StaticNodeDebugInfo = new CompileIdentifierMetadata<dynamic>(
      name: "StaticNodeDebugInfo",
      moduleUrl: 'asset:angular/lib/src/debug/debug_context.dart');
  static final DebugContext = new CompileIdentifierMetadata<dynamic>(
      name: "DebugContext",
      moduleUrl: 'asset:angular/lib/src/debug/debug_context.dart');
  static final TemplateSecurityContext = new CompileIdentifierMetadata<dynamic>(
      name: 'TemplateSecurityContext',
      moduleUrl: 'asset:angular/lib/src/core/security.dart');
  static final SimpleChange = new CompileIdentifierMetadata<dynamic>(
      name: "SimpleChange", moduleUrl: CD_MODULE_URL);
  static final ChangeDetectorState = new CompileIdentifierMetadata<dynamic>(
      name: "ChangeDetectorState", moduleUrl: CD_MODULE_URL);
  static final checkBinding = new CompileIdentifierMetadata<dynamic>(
      name: "checkBinding", moduleUrl: APP_VIEW_UTILS_MODULE_URL);
  static final createAndAppend = new CompileIdentifierMetadata<dynamic>(
      name: "createAndAppend", moduleUrl: APP_VIEW_MODULE_URL);
  static final createAndAppendDbg = new CompileIdentifierMetadata<dynamic>(
      name: "createAndAppendDbg", moduleUrl: DEBUG_APP_VIEW_MODULE_URL);
  static final createAndAppendToShadowRoot =
      new CompileIdentifierMetadata<dynamic>(
          name: "createAndAppendToShadowRoot", moduleUrl: APP_VIEW_MODULE_URL);
  static final createAndAppendToShadowRootDbg =
      new CompileIdentifierMetadata<dynamic>(
          name: "createAndAppendToShadowRootDbg",
          moduleUrl: DEBUG_APP_VIEW_MODULE_URL);
  static final dbgElm = new CompileIdentifierMetadata<dynamic>(
      name: "dbgElm", moduleUrl: DEBUG_APP_VIEW_MODULE_URL);
  static final devModeEqual = new CompileIdentifierMetadata<dynamic>(
      name: "devModeEqual", moduleUrl: CD_MODULE_URL);
  static final looseIdentical = new CompileIdentifierMetadata<dynamic>(
      name: "looseIdentical",
      moduleUrl: 'asset:angular/lib/src/facade/lang.dart');
  static final profileSetup = new CompileIdentifierMetadata<dynamic>(
      name: "profileSetup", moduleUrl: PROFILE_RUNTIME_MODULE_URL);
  static final profileMarkStart = new CompileIdentifierMetadata<dynamic>(
      name: "profileMarkStart", moduleUrl: PROFILE_RUNTIME_MODULE_URL);
  static final profileMarkEnd = new CompileIdentifierMetadata<dynamic>(
      name: "profileMarkEnd", moduleUrl: PROFILE_RUNTIME_MODULE_URL);

  /// String interpolation where prefix,suffix are empty
  /// (most common case).
  static final throwOnChanges = new CompileIdentifierMetadata<dynamic>(
      name: "AppViewUtils.throwOnChanges",
      moduleUrl: APP_VIEW_UTILS_MODULE_URL);
  static final interpolate = <CompileIdentifierMetadata>[
    new CompileIdentifierMetadata<dynamic>(
        name: "interpolate0", moduleUrl: APP_VIEW_UTILS_MODULE_URL),
    new CompileIdentifierMetadata<dynamic>(
        name: "interpolate1", moduleUrl: APP_VIEW_UTILS_MODULE_URL),
    new CompileIdentifierMetadata<dynamic>(
        name: "interpolate2", moduleUrl: APP_VIEW_UTILS_MODULE_URL),
    new CompileIdentifierMetadata<dynamic>(
        name: "interpolate3", moduleUrl: APP_VIEW_UTILS_MODULE_URL),
    new CompileIdentifierMetadata<dynamic>(
        name: "interpolate4", moduleUrl: APP_VIEW_UTILS_MODULE_URL),
    new CompileIdentifierMetadata<dynamic>(
        name: "interpolate5", moduleUrl: APP_VIEW_UTILS_MODULE_URL),
    new CompileIdentifierMetadata<dynamic>(
        name: "interpolate6", moduleUrl: APP_VIEW_UTILS_MODULE_URL),
    new CompileIdentifierMetadata<dynamic>(
        name: "interpolate7", moduleUrl: APP_VIEW_UTILS_MODULE_URL),
    new CompileIdentifierMetadata<dynamic>(
        name: "interpolate8", moduleUrl: APP_VIEW_UTILS_MODULE_URL),
    new CompileIdentifierMetadata<dynamic>(
        name: "interpolate9", moduleUrl: APP_VIEW_UTILS_MODULE_URL),
  ];
  static final castByValue = new CompileIdentifierMetadata<dynamic>(
      name: "castByValue", moduleUrl: APP_VIEW_UTILS_MODULE_URL);
  static final EMPTY_ARRAY = new CompileIdentifierMetadata<dynamic>(
      name: "EMPTY_ARRAY", moduleUrl: APP_VIEW_UTILS_MODULE_URL);
  static final EMPTY_MAP = new CompileIdentifierMetadata<dynamic>(
      name: "EMPTY_MAP", moduleUrl: APP_VIEW_UTILS_MODULE_URL);
  static final NG_IF_DIRECTIVE = new CompileIdentifierMetadata<dynamic>(
      name: "NgIf", moduleUrl: NG_IF_URL);
  static final NG_FOR_DIRECTIVE = new CompileIdentifierMetadata<dynamic>(
      name: "NgFor", moduleUrl: NG_FOR_URL);
  static final pureProxies = [
    null,
    new CompileIdentifierMetadata<dynamic>(
        name: "pureProxy1", moduleUrl: APP_VIEW_UTILS_MODULE_URL),
    new CompileIdentifierMetadata<dynamic>(
        name: "pureProxy2", moduleUrl: APP_VIEW_UTILS_MODULE_URL),
    new CompileIdentifierMetadata<dynamic>(
        name: "pureProxy3", moduleUrl: APP_VIEW_UTILS_MODULE_URL),
    new CompileIdentifierMetadata<dynamic>(
        name: "pureProxy4", moduleUrl: APP_VIEW_UTILS_MODULE_URL),
    new CompileIdentifierMetadata<dynamic>(
        name: "pureProxy5", moduleUrl: APP_VIEW_UTILS_MODULE_URL),
    new CompileIdentifierMetadata<dynamic>(
        name: "pureProxy6", moduleUrl: APP_VIEW_UTILS_MODULE_URL),
    new CompileIdentifierMetadata<dynamic>(
        name: "pureProxy7", moduleUrl: APP_VIEW_UTILS_MODULE_URL),
    new CompileIdentifierMetadata<dynamic>(
        name: "pureProxy8", moduleUrl: APP_VIEW_UTILS_MODULE_URL),
    new CompileIdentifierMetadata<dynamic>(
        name: "pureProxy9", moduleUrl: APP_VIEW_UTILS_MODULE_URL),
    new CompileIdentifierMetadata<dynamic>(
        name: "pureProxy10", moduleUrl: APP_VIEW_UTILS_MODULE_URL)
  ];
  // Runtime is initialized by output interpreter. Compiler executes in VM and
  // can't import dart:html to initialize here.
  static var HTML_COMMENT_NODE = new CompileIdentifierMetadata<dynamic>(
      name: "Comment", moduleUrl: "dart:html");
  static var HTML_TEXT_NODE = new CompileIdentifierMetadata<dynamic>(
      name: "Text", moduleUrl: "dart:html");
  static var HTML_DOCUMENT = new CompileIdentifierMetadata<dynamic>(
      name: "document", moduleUrl: "dart:html");
  static final HTML_ELEMENT = new CompileIdentifierMetadata<dynamic>(
      name: "Element", moduleUrl: "dart:html");
  static final ElementToken = identifierToken(HTML_ELEMENT);
  static final HTML_HTML_ELEMENT = new CompileIdentifierMetadata<dynamic>(
      name: "HtmlElement", moduleUrl: "dart:html");
  static final HtmlElementToken = identifierToken(HTML_HTML_ELEMENT);
  static final HTML_SHADOW_ROOT_ELEMENT =
      new CompileIdentifierMetadata<dynamic>(
          name: "ShadowRoot", moduleUrl: "dart:html");
  static final SVG_ELEMENT = new CompileIdentifierMetadata<dynamic>(
      name: "SvgElement", moduleUrl: "dart:svg");
  static final HTML_ANCHOR_ELEMENT = new CompileIdentifierMetadata<dynamic>(
      name: "AnchorElement", moduleUrl: "dart:html");
  static final HTML_DIV_ELEMENT = new CompileIdentifierMetadata<dynamic>(
      name: "DivElement", moduleUrl: "dart:html");
  static final HTML_AREA_ELEMENT = new CompileIdentifierMetadata<dynamic>(
      name: "AreaElement", moduleUrl: "dart:html");
  static final HTML_AUDIO_ELEMENT = new CompileIdentifierMetadata<dynamic>(
      name: "AudioElement", moduleUrl: "dart:html");
  static final HTML_BUTTON_ELEMENT = new CompileIdentifierMetadata<dynamic>(
      name: "ButtonElement", moduleUrl: "dart:html");
  static final HTML_CANVAS_ELEMENT = new CompileIdentifierMetadata<dynamic>(
      name: "CanvasElement", moduleUrl: "dart:html");
  static final HTML_FORM_ELEMENT = new CompileIdentifierMetadata<dynamic>(
      name: "FormElement", moduleUrl: "dart:html");
  static final HTML_IFRAME_ELEMENT = new CompileIdentifierMetadata<dynamic>(
      name: "IFrameElement", moduleUrl: "dart:html");
  static final HTML_IMAGE_ELEMENT = new CompileIdentifierMetadata<dynamic>(
      name: "ImageElement", moduleUrl: "dart:html");
  static final HTML_INPUT_ELEMENT = new CompileIdentifierMetadata<dynamic>(
      name: "InputElement", moduleUrl: "dart:html");
  static final HTML_TEXTAREA_ELEMENT = new CompileIdentifierMetadata<dynamic>(
      name: "TextAreaElement", moduleUrl: "dart:html");
  static final HTML_MEDIA_ELEMENT = new CompileIdentifierMetadata<dynamic>(
      name: "MediaElement", moduleUrl: "dart:html");
  static final HTML_MENU_ELEMENT = new CompileIdentifierMetadata<dynamic>(
      name: "MenuElement", moduleUrl: "dart:html");
  static final HTML_OPTION_ELEMENT = new CompileIdentifierMetadata<dynamic>(
      name: "OptionElement", moduleUrl: "dart:html");
  static final HTML_OLIST_ELEMENT = new CompileIdentifierMetadata<dynamic>(
      name: "OListElement", moduleUrl: "dart:html");
  static final HTML_SELECT_ELEMENT = new CompileIdentifierMetadata<dynamic>(
      name: "SelectElement", moduleUrl: "dart:html");
  static final HTML_TABLE_ELEMENT = new CompileIdentifierMetadata<dynamic>(
      name: "TableElement", moduleUrl: "dart:html");
  static final HTML_TABLE_ROW_ELEMENT = new CompileIdentifierMetadata<dynamic>(
      name: "TableRowElement", moduleUrl: "dart:html");
  static final HTML_TABLE_COL_ELEMENT = new CompileIdentifierMetadata<dynamic>(
      name: "TableColElement", moduleUrl: "dart:html");
  static final HTML_ULIST_ELEMENT = new CompileIdentifierMetadata<dynamic>(
      name: "UListElement", moduleUrl: "dart:html");
  static final HTML_EVENT = new CompileIdentifierMetadata<dynamic>(
      name: "Event", moduleUrl: "dart:html");
  static final HTML_NODE = new CompileIdentifierMetadata<dynamic>(
      name: "Node", moduleUrl: "dart:html");
}

CompileTokenMetadata identifierToken(CompileIdentifierMetadata identifier) {
  return new CompileTokenMetadata(identifier: identifier);
}
