import "package:angular2/src/core/change_detection/change_detection.dart"
    show
        devModeEqual,
        SimpleChange,
        ValueUnwrapper,
        ChangeDetectorRef,
        ChangeDetectorState,
        ChangeDetectionStrategy;
import "package:angular2/src/core/di/injector.dart" show Injector;
import "package:angular2/src/core/linker/app_view_utils.dart"
    show
        AppViewUtils,
        interpolate,
        interpolate0,
        interpolate1,
        interpolate2,
        checkBinding,
        castByValue,
        EMPTY_ARRAY,
        EMPTY_MAP,
        pureProxy1,
        pureProxy2,
        pureProxy3,
        pureProxy4,
        pureProxy5,
        pureProxy6,
        pureProxy7,
        pureProxy8,
        pureProxy9,
        pureProxy10;
import "package:angular2/src/core/linker/element_ref.dart" show ElementRef;
import "package:angular2/src/core/linker/view_type.dart" show ViewType;
import "package:angular2/src/core/metadata/view.dart" show ViewEncapsulation;
import "package:angular2/src/core/render/api.dart" show RenderComponentType;
import "package:angular2/src/core/security.dart" show TemplateSecurityContext;
import "package:angular2/src/facade/lang.dart" show looseIdentical;

import "compile_metadata.dart"
    show CompileIdentifierMetadata, CompileTokenMetadata;

var APP_VIEW_MODULE_URL = "asset:angular2/lib/src/core/linker/app_view.dart";
var DEBUG_APP_VIEW_MODULE_URL =
    "asset:angular2/lib/src/debug/debug_app_view.dart";
var APP_VIEW_UTILS_MODULE_URL =
    "asset:angular2/lib/src/core/linker/app_view_utils.dart";
var CD_MODULE_URL =
    "asset:angular2/lib/src/core/change_detection/change_detection.dart";
var ANGULAR_ROOT_URL = "package:angular2/angular2.dart";
var NG_IF_URL = "asset:angular2/lib/src/common/directives/ng_if.dart";
var NG_FOR_URL = "asset:angular2/lib/src/common/directives/ng_for.dart";

// Reassign the imports to different variables so we can
// define static variables with the name of the import.

var impElementRef = ElementRef;
var impChangeDetectorRef = ChangeDetectorRef;
var impRenderComponentType = RenderComponentType;
var impValueUnwrapper = ValueUnwrapper;
var impInjector = Injector;
var impViewEncapsulation = ViewEncapsulation;
var impViewType = ViewType;
var impChangeDetectionStrategy = ChangeDetectionStrategy;
var impSimpleChange = SimpleChange;
var impChangeDetectorState = ChangeDetectorState;
var impDevModeEqual = devModeEqual;
var impInterpolate0 = interpolate0;
var impInterpolate1 = interpolate1;
var impInterpolate2 = interpolate2;
var impThrowOnChanges = () => AppViewUtils.throwOnChanges;
var impInterpolate = interpolate;
var impCheckBinding = checkBinding;
var impLooseIdentical = looseIdentical;
var impCastByValue = castByValue;
var impTemplateSecurityContext = TemplateSecurityContext;
var impEMPTY_ARRAY = EMPTY_ARRAY;
var impEMPTY_MAP = EMPTY_MAP;

class Identifiers {
  static final appViewUtils = new CompileIdentifierMetadata(
      name: "appViewUtils", moduleUrl: APP_VIEW_UTILS_MODULE_URL);
  static final ngAnchor = new CompileIdentifierMetadata(
      name: 'ngAnchor', moduleUrl: APP_VIEW_MODULE_URL);
  static final AppView = new CompileIdentifierMetadata(
      name: "AppView", moduleUrl: APP_VIEW_MODULE_URL);
  static final DebugAppView = new CompileIdentifierMetadata(
      name: "DebugAppView", moduleUrl: DEBUG_APP_VIEW_MODULE_URL);
  static final ViewContainer = new CompileIdentifierMetadata(
      name: "ViewContainer",
      moduleUrl: "asset:angular2/lib/src/core/linker/view_container.dart");
  static final ElementRef = new CompileIdentifierMetadata(
      name: "ElementRef",
      moduleUrl: "asset:angular2/lib/src/core/linker/element_ref.dart",
      runtime: impElementRef);
  static final ViewContainerRef = new CompileIdentifierMetadata(
      name: "ViewContainerRef",
      moduleUrl: "asset:angular2/lib/src/core/linker/view_container_ref.dart");
  static final ChangeDetectorRef = new CompileIdentifierMetadata(
      name: "ChangeDetectorRef",
      moduleUrl: 'asset:angular2/lib/src/core/change_detection/'
          'change_detector_ref.dart',
      runtime: impChangeDetectorRef);
  static final ComponentFactory = new CompileIdentifierMetadata(
      name: 'ComponentFactory', moduleUrl: ANGULAR_ROOT_URL);
  static final RenderComponentType = new CompileIdentifierMetadata(
      name: "RenderComponentType",
      moduleUrl: "asset:angular2/lib/src/core/render/api.dart",
      runtime: impRenderComponentType);
  static final ComponentRef = new CompileIdentifierMetadata(
      name: "ComponentRef", moduleUrl: ANGULAR_ROOT_URL);
  static final QueryList = new CompileIdentifierMetadata(
      name: "QueryList",
      moduleUrl: "asset:angular2/lib/src/core/linker/query_list.dart");
  static final TemplateRef = new CompileIdentifierMetadata(
      name: "TemplateRef",
      moduleUrl: "asset:angular2/lib/src/core/linker/template_ref.dart");
  static final ValueUnwrapper = new CompileIdentifierMetadata(
      name: "ValueUnwrapper",
      moduleUrl: CD_MODULE_URL,
      runtime: impValueUnwrapper);
  static final Injector = new CompileIdentifierMetadata(
      name: "Injector",
      moduleUrl: 'asset:angular2/lib/src/core/di/injector.dart',
      runtime: impInjector);
  static final ViewEncapsulation = new CompileIdentifierMetadata(
      name: "ViewEncapsulation",
      moduleUrl: ANGULAR_ROOT_URL,
      runtime: impViewEncapsulation);
  static final ViewType = new CompileIdentifierMetadata(
      name: "ViewType",
      moduleUrl: 'asset:angular2/lib/src/core/linker/view_type.dart',
      runtime: impViewType);
  static final ChangeDetectionStrategy = new CompileIdentifierMetadata(
      name: "ChangeDetectionStrategy",
      moduleUrl: CD_MODULE_URL,
      runtime: impChangeDetectionStrategy);
  static final StaticNodeDebugInfo = new CompileIdentifierMetadata(
      name: "StaticNodeDebugInfo",
      moduleUrl: 'asset:angular2/lib/src/debug/debug_context.dart');
  static final DebugContext = new CompileIdentifierMetadata(
      name: "DebugContext",
      moduleUrl: 'asset:angular2/lib/src/debug/debug_context.dart');
  static final TemplateSecurityContext = new CompileIdentifierMetadata(
      name: 'TemplateSecurityContext',
      moduleUrl: 'asset:angular2/lib/src/core/security.dart',
      runtime: impTemplateSecurityContext);
  static final SimpleChange = new CompileIdentifierMetadata(
      name: "SimpleChange", moduleUrl: CD_MODULE_URL, runtime: impSimpleChange);
  static final ChangeDetectorState = new CompileIdentifierMetadata(
      name: "ChangeDetectorState",
      moduleUrl: CD_MODULE_URL,
      runtime: impChangeDetectorState);
  static final checkBinding = new CompileIdentifierMetadata(
      name: "checkBinding",
      moduleUrl: APP_VIEW_UTILS_MODULE_URL,
      runtime: impCheckBinding);
  static final devModeEqual = new CompileIdentifierMetadata(
      name: "devModeEqual", moduleUrl: CD_MODULE_URL, runtime: impDevModeEqual);
  static final looseIdentical = new CompileIdentifierMetadata(
      name: "looseIdentical",
      moduleUrl: 'asset:angular2/lib/src/facade/lang.dart',
      runtime: impLooseIdentical);

  /// String interpolation where prefix,suffix are empty
  /// (most common case).
  static final throwOnChanges = new CompileIdentifierMetadata(
      name: "AppViewUtils.throwOnChanges",
      moduleUrl: APP_VIEW_UTILS_MODULE_URL,
      runtimeCallback: impThrowOnChanges);
  static final interpolate0 = new CompileIdentifierMetadata(
      name: "interpolate0",
      moduleUrl: APP_VIEW_UTILS_MODULE_URL,
      runtime: impInterpolate0);
  static final interpolate1 = new CompileIdentifierMetadata(
      name: "interpolate1",
      moduleUrl: APP_VIEW_UTILS_MODULE_URL,
      runtime: impInterpolate1);
  static final interpolate2 = new CompileIdentifierMetadata(
      name: "interpolate2",
      moduleUrl: APP_VIEW_UTILS_MODULE_URL,
      runtime: impInterpolate2);
  static final interpolate = new CompileIdentifierMetadata(
      name: "interpolate",
      moduleUrl: APP_VIEW_UTILS_MODULE_URL,
      runtime: impInterpolate);
  static final castByValue = new CompileIdentifierMetadata(
      name: "castByValue",
      moduleUrl: APP_VIEW_UTILS_MODULE_URL,
      runtime: impCastByValue);
  static final EMPTY_ARRAY = new CompileIdentifierMetadata(
      name: "EMPTY_ARRAY",
      moduleUrl: APP_VIEW_UTILS_MODULE_URL,
      runtime: impEMPTY_ARRAY);
  static final EMPTY_MAP = new CompileIdentifierMetadata(
      name: "EMPTY_MAP",
      moduleUrl: APP_VIEW_UTILS_MODULE_URL,
      runtime: impEMPTY_MAP);
  static final NG_IF_DIRECTIVE =
      new CompileIdentifierMetadata(name: "NgIf", moduleUrl: NG_IF_URL);
  static final NG_FOR_DIRECTIVE =
      new CompileIdentifierMetadata(name: "NgFor", moduleUrl: NG_FOR_URL);
  static final pureProxies = [
    null,
    new CompileIdentifierMetadata(
        name: "pureProxy1",
        moduleUrl: APP_VIEW_UTILS_MODULE_URL,
        runtime: (f(p0)) => pureProxy1(f)),
    new CompileIdentifierMetadata(
        name: "pureProxy2",
        moduleUrl: APP_VIEW_UTILS_MODULE_URL,
        runtime: (f(p0, p1)) => pureProxy2(f)),
    new CompileIdentifierMetadata(
        name: "pureProxy3",
        moduleUrl: APP_VIEW_UTILS_MODULE_URL,
        runtime: (f(p0, p1, p2)) => pureProxy3(f)),
    new CompileIdentifierMetadata(
        name: "pureProxy4",
        moduleUrl: APP_VIEW_UTILS_MODULE_URL,
        runtime: (f(p0, p1, p2, p3)) => pureProxy4(f)),
    new CompileIdentifierMetadata(
        name: "pureProxy5",
        moduleUrl: APP_VIEW_UTILS_MODULE_URL,
        runtime: (f(p0, p1, p2, p3, p4)) => pureProxy5(f)),
    new CompileIdentifierMetadata(
        name: "pureProxy6",
        moduleUrl: APP_VIEW_UTILS_MODULE_URL,
        runtime: (f(p0, p1, p2, p3, p4, p5)) => pureProxy6(f)),
    new CompileIdentifierMetadata(
        name: "pureProxy7",
        moduleUrl: APP_VIEW_UTILS_MODULE_URL,
        runtime: (f(p0, p1, p2, p3, p4, p5, p6)) => pureProxy7(f)),
    new CompileIdentifierMetadata(
        name: "pureProxy8",
        moduleUrl: APP_VIEW_UTILS_MODULE_URL,
        runtime: (f(p0, p1, p2, p3, p4, p5, p6, p7)) => pureProxy8(f)),
    new CompileIdentifierMetadata(
        name: "pureProxy9",
        moduleUrl: APP_VIEW_UTILS_MODULE_URL,
        runtime: (f(p0, p1, p2, p3, p4, p5, p6, p7, p8)) => pureProxy9(f)),
    new CompileIdentifierMetadata(
        name: "pureProxy10",
        moduleUrl: APP_VIEW_UTILS_MODULE_URL,
        runtime: (f(p0, p1, p2, p3, p4, p5, p6, p7, p8, p9)) => pureProxy10(f))
  ];
  // Runtime is initialized by output interpreter. Compiler executes in VM and
  // can't import dart:html to initialize here.
  static var HTML_COMMENT_NODE =
      new CompileIdentifierMetadata(name: "Comment", moduleUrl: "dart:html");
  static var HTML_TEXT_NODE =
      new CompileIdentifierMetadata(name: "Text", moduleUrl: "dart:html");
  static var HTML_DOCUMENT =
      new CompileIdentifierMetadata(name: "document", moduleUrl: "dart:html");
  static final HTML_ELEMENT =
      new CompileIdentifierMetadata(name: "Element", moduleUrl: "dart:html");
  static final HTML_HTML_ELEMENT = new CompileIdentifierMetadata(
      name: "HtmlElement", moduleUrl: "dart:html");
  static final HTML_SHADOW_ROOT_ELEMENT =
      new CompileIdentifierMetadata(name: "ShadowRoot", moduleUrl: "dart:html");
  static final SVG_ELEMENT =
      new CompileIdentifierMetadata(name: "SvgElement", moduleUrl: "dart:svg");
  static final HTML_ANCHOR_ELEMENT = new CompileIdentifierMetadata(
      name: "AnchorElement", moduleUrl: "dart:html");
  static final HTML_DIV_ELEMENT =
      new CompileIdentifierMetadata(name: "DivElement", moduleUrl: "dart:html");
  static final HTML_AREA_ELEMENT = new CompileIdentifierMetadata(
      name: "AreaElement", moduleUrl: "dart:html");
  static final HTML_AUDIO_ELEMENT = new CompileIdentifierMetadata(
      name: "AudioElement", moduleUrl: "dart:html");
  static final HTML_BUTTON_ELEMENT = new CompileIdentifierMetadata(
      name: "ButtonElement", moduleUrl: "dart:html");
  static final HTML_CANVAS_ELEMENT = new CompileIdentifierMetadata(
      name: "CanvasElement", moduleUrl: "dart:html");
  static final HTML_FORM_ELEMENT = new CompileIdentifierMetadata(
      name: "FormElement", moduleUrl: "dart:html");
  static final HTML_IFRAME_ELEMENT = new CompileIdentifierMetadata(
      name: "IFrameElement", moduleUrl: "dart:html");
  static final HTML_IMAGE_ELEMENT = new CompileIdentifierMetadata(
      name: "ImageElement", moduleUrl: "dart:html");
  static final HTML_INPUT_ELEMENT = new CompileIdentifierMetadata(
      name: "InputElement", moduleUrl: "dart:html");
  static final HTML_TEXTAREA_ELEMENT = new CompileIdentifierMetadata(
      name: "TextAreaElement", moduleUrl: "dart:html");
  static final HTML_MEDIA_ELEMENT = new CompileIdentifierMetadata(
      name: "MediaElement", moduleUrl: "dart:html");
  static final HTML_MENU_ELEMENT = new CompileIdentifierMetadata(
      name: "MenuElement", moduleUrl: "dart:html");
  static final HTML_OPTION_ELEMENT = new CompileIdentifierMetadata(
      name: "OptionElement", moduleUrl: "dart:html");
  static final HTML_OLIST_ELEMENT = new CompileIdentifierMetadata(
      name: "OListElement", moduleUrl: "dart:html");
  static final HTML_SELECT_ELEMENT = new CompileIdentifierMetadata(
      name: "SelectElement", moduleUrl: "dart:html");
  static final HTML_TABLE_ELEMENT = new CompileIdentifierMetadata(
      name: "TableElement", moduleUrl: "dart:html");
  static final HTML_TABLE_ROW_ELEMENT = new CompileIdentifierMetadata(
      name: "TableRowElement", moduleUrl: "dart:html");
  static final HTML_TABLE_COL_ELEMENT = new CompileIdentifierMetadata(
      name: "TableColElement", moduleUrl: "dart:html");
  static final HTML_ULIST_ELEMENT = new CompileIdentifierMetadata(
      name: "UListElement", moduleUrl: "dart:html");
  static final HTML_EVENT =
      new CompileIdentifierMetadata(name: "Event", moduleUrl: "dart:html");
  static final HTML_NODE =
      new CompileIdentifierMetadata(name: "Node", moduleUrl: "dart:html");
}

CompileTokenMetadata identifierToken(CompileIdentifierMetadata identifier) {
  return new CompileTokenMetadata(identifier: identifier);
}
