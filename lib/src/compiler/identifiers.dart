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
      moduleUrl: "asset:angular2/lib/src/core/linker/view_container.dart");
  static final ElementRef = new CompileIdentifierMetadata<dynamic>(
      name: "ElementRef",
      moduleUrl: "asset:angular2/lib/src/core/linker/element_ref.dart",
      runtime: impElementRef);
  static final ViewContainerRef = new CompileIdentifierMetadata<dynamic>(
      name: "ViewContainerRef",
      moduleUrl: "asset:angular2/lib/src/core/linker/view_container_ref.dart");
  static final ChangeDetectorRef = new CompileIdentifierMetadata<dynamic>(
      name: "ChangeDetectorRef",
      moduleUrl: 'asset:angular2/lib/src/core/change_detection/'
          'change_detector_ref.dart',
      runtime: impChangeDetectorRef);
  static final ComponentFactory = new CompileIdentifierMetadata<dynamic>(
      name: 'ComponentFactory', moduleUrl: ANGULAR_ROOT_URL);
  static final RenderComponentType = new CompileIdentifierMetadata<dynamic>(
      name: "RenderComponentType",
      moduleUrl: "asset:angular2/lib/src/core/render/api.dart",
      runtime: impRenderComponentType);
  static final ComponentRef = new CompileIdentifierMetadata<dynamic>(
      name: "ComponentRef", moduleUrl: ANGULAR_ROOT_URL);
  static final QueryList = new CompileIdentifierMetadata<dynamic>(
      name: "QueryList",
      moduleUrl: "asset:angular2/lib/src/core/linker/query_list.dart");
  static final TemplateRef = new CompileIdentifierMetadata<dynamic>(
      name: "TemplateRef",
      moduleUrl: "asset:angular2/lib/src/core/linker/template_ref.dart");
  static final ValueUnwrapper = new CompileIdentifierMetadata<dynamic>(
      name: "ValueUnwrapper",
      moduleUrl: CD_MODULE_URL,
      runtime: impValueUnwrapper);
  static final Injector = new CompileIdentifierMetadata<dynamic>(
      name: "Injector",
      moduleUrl: 'asset:angular2/lib/src/core/di/injector.dart',
      runtime: impInjector);
  static final ViewEncapsulation = new CompileIdentifierMetadata<dynamic>(
      name: "ViewEncapsulation",
      moduleUrl: ANGULAR_ROOT_URL,
      runtime: impViewEncapsulation);
  static final ViewType = new CompileIdentifierMetadata<dynamic>(
      name: "ViewType",
      moduleUrl: 'asset:angular2/lib/src/core/linker/view_type.dart',
      runtime: impViewType);
  static final ChangeDetectionStrategy = new CompileIdentifierMetadata<dynamic>(
      name: "ChangeDetectionStrategy",
      moduleUrl: CD_MODULE_URL,
      runtime: impChangeDetectionStrategy);
  static final StaticNodeDebugInfo = new CompileIdentifierMetadata<dynamic>(
      name: "StaticNodeDebugInfo",
      moduleUrl: 'asset:angular2/lib/src/debug/debug_context.dart');
  static final DebugContext = new CompileIdentifierMetadata<dynamic>(
      name: "DebugContext",
      moduleUrl: 'asset:angular2/lib/src/debug/debug_context.dart');
  static final TemplateSecurityContext = new CompileIdentifierMetadata<dynamic>(
      name: 'TemplateSecurityContext',
      moduleUrl: 'asset:angular2/lib/src/core/security.dart',
      runtime: impTemplateSecurityContext);
  static final SimpleChange = new CompileIdentifierMetadata<dynamic>(
      name: "SimpleChange", moduleUrl: CD_MODULE_URL, runtime: impSimpleChange);
  static final ChangeDetectorState = new CompileIdentifierMetadata<dynamic>(
      name: "ChangeDetectorState",
      moduleUrl: CD_MODULE_URL,
      runtime: impChangeDetectorState);
  static final checkBinding = new CompileIdentifierMetadata<dynamic>(
      name: "checkBinding",
      moduleUrl: APP_VIEW_UTILS_MODULE_URL,
      runtime: impCheckBinding);
  static final devModeEqual = new CompileIdentifierMetadata<dynamic>(
      name: "devModeEqual", moduleUrl: CD_MODULE_URL, runtime: impDevModeEqual);
  static final looseIdentical = new CompileIdentifierMetadata<dynamic>(
      name: "looseIdentical",
      moduleUrl: 'asset:angular2/lib/src/facade/lang.dart',
      runtime: impLooseIdentical);

  /// String interpolation where prefix,suffix are empty
  /// (most common case).
  static final throwOnChanges = new CompileIdentifierMetadata<dynamic>(
      name: "AppViewUtils.throwOnChanges",
      moduleUrl: APP_VIEW_UTILS_MODULE_URL,
      runtimeCallback: impThrowOnChanges);
  static final interpolate0 = new CompileIdentifierMetadata<dynamic>(
      name: "interpolate0",
      moduleUrl: APP_VIEW_UTILS_MODULE_URL,
      runtime: impInterpolate0);
  static final interpolate1 = new CompileIdentifierMetadata<dynamic>(
      name: "interpolate1",
      moduleUrl: APP_VIEW_UTILS_MODULE_URL,
      runtime: impInterpolate1);
  static final interpolate2 = new CompileIdentifierMetadata<dynamic>(
      name: "interpolate2",
      moduleUrl: APP_VIEW_UTILS_MODULE_URL,
      runtime: impInterpolate2);
  static final interpolate = new CompileIdentifierMetadata<dynamic>(
      name: "interpolate",
      moduleUrl: APP_VIEW_UTILS_MODULE_URL,
      runtime: impInterpolate);
  static final castByValue = new CompileIdentifierMetadata<dynamic>(
      name: "castByValue",
      moduleUrl: APP_VIEW_UTILS_MODULE_URL,
      runtime: impCastByValue);
  static final EMPTY_ARRAY = new CompileIdentifierMetadata<dynamic>(
      name: "EMPTY_ARRAY",
      moduleUrl: APP_VIEW_UTILS_MODULE_URL,
      runtime: impEMPTY_ARRAY);
  static final EMPTY_MAP = new CompileIdentifierMetadata<dynamic>(
      name: "EMPTY_MAP",
      moduleUrl: APP_VIEW_UTILS_MODULE_URL,
      runtime: impEMPTY_MAP);
  static final NG_IF_DIRECTIVE = new CompileIdentifierMetadata<dynamic>(
      name: "NgIf", moduleUrl: NG_IF_URL);
  static final NG_FOR_DIRECTIVE = new CompileIdentifierMetadata<dynamic>(
      name: "NgFor", moduleUrl: NG_FOR_URL);
  static final pureProxies = [
    null,
    new CompileIdentifierMetadata<dynamic>(
        name: "pureProxy1",
        moduleUrl: APP_VIEW_UTILS_MODULE_URL,
        runtime: (f(p0)) => pureProxy1(f)),
    new CompileIdentifierMetadata<dynamic>(
        name: "pureProxy2",
        moduleUrl: APP_VIEW_UTILS_MODULE_URL,
        runtime: (f(p0, p1)) => pureProxy2(f)),
    new CompileIdentifierMetadata<dynamic>(
        name: "pureProxy3",
        moduleUrl: APP_VIEW_UTILS_MODULE_URL,
        runtime: (f(p0, p1, p2)) => pureProxy3(f)),
    new CompileIdentifierMetadata<dynamic>(
        name: "pureProxy4",
        moduleUrl: APP_VIEW_UTILS_MODULE_URL,
        runtime: (f(p0, p1, p2, p3)) => pureProxy4(f)),
    new CompileIdentifierMetadata<dynamic>(
        name: "pureProxy5",
        moduleUrl: APP_VIEW_UTILS_MODULE_URL,
        runtime: (f(p0, p1, p2, p3, p4)) => pureProxy5(f)),
    new CompileIdentifierMetadata<dynamic>(
        name: "pureProxy6",
        moduleUrl: APP_VIEW_UTILS_MODULE_URL,
        runtime: (f(p0, p1, p2, p3, p4, p5)) => pureProxy6(f)),
    new CompileIdentifierMetadata<dynamic>(
        name: "pureProxy7",
        moduleUrl: APP_VIEW_UTILS_MODULE_URL,
        runtime: (f(p0, p1, p2, p3, p4, p5, p6)) => pureProxy7(f)),
    new CompileIdentifierMetadata<dynamic>(
        name: "pureProxy8",
        moduleUrl: APP_VIEW_UTILS_MODULE_URL,
        runtime: (f(p0, p1, p2, p3, p4, p5, p6, p7)) => pureProxy8(f)),
    new CompileIdentifierMetadata<dynamic>(
        name: "pureProxy9",
        moduleUrl: APP_VIEW_UTILS_MODULE_URL,
        runtime: (f(p0, p1, p2, p3, p4, p5, p6, p7, p8)) => pureProxy9(f)),
    new CompileIdentifierMetadata<dynamic>(
        name: "pureProxy10",
        moduleUrl: APP_VIEW_UTILS_MODULE_URL,
        runtime: (f(p0, p1, p2, p3, p4, p5, p6, p7, p8, p9)) => pureProxy10(f))
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
  static final HTML_HTML_ELEMENT = new CompileIdentifierMetadata<dynamic>(
      name: "HtmlElement", moduleUrl: "dart:html");
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
