import "package:angular2/src/core/change_detection/change_detection.dart"
    show
        uninitialized,
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
import "package:angular2/src/core/linker/injector_factory.dart"
    show CodegenInjector, CodegenInjectorFactory;
import "package:angular2/src/core/linker/view_type.dart" show ViewType;
import "package:angular2/src/core/metadata/view.dart" show ViewEncapsulation;
import "package:angular2/src/core/render/api.dart"
    show Renderer, RenderComponentType;
import "package:angular2/src/core/security.dart" show TemplateSecurityContext;

import "compile_metadata.dart"
    show CompileIdentifierMetadata, CompileTokenMetadata;

var APP_VIEW_MODULE_URL = "asset:angular2/lib/src/core/linker/app_view.dart";
var DEBUG_APP_VIEW_MODULE_URL =
    "asset:angular2/lib/src/debug/debug_app_view.dart";
var APP_VIEW_UTILS_MODULE_URL =
    "asset:angular2/lib/src/core/linker/app_view_utils.dart";
var CD_MODULE_URL =
    "asset:angular2/lib/src/core/change_detection/change_detection.dart";

// Reassign the imports to different variables so we can
// define static variables with the name of the import.

var impElementRef = ElementRef;
var impChangeDetectorRef = ChangeDetectorRef;
var impRenderComponentType = RenderComponentType;
var impValueUnwrapper = ValueUnwrapper;
var impInjector = Injector;
var impCodegenInjector = CodegenInjector;
var impCodegenInjectorFactory = CodegenInjectorFactory;
var impViewEncapsulation = ViewEncapsulation;
var impViewType = ViewType;
var impChangeDetectionStrategy = ChangeDetectionStrategy;
var impRenderer = Renderer;
var impSimpleChange = SimpleChange;
var impUninitialized = uninitialized;
var impChangeDetectorState = ChangeDetectorState;
var impDevModeEqual = devModeEqual;
var impInterpolate0 = interpolate0;
var impInterpolate1 = interpolate1;
var impInterpolate2 = interpolate2;
var impThrowOnChanges = () => AppViewUtils.throwOnChanges;
var impInterpolate = interpolate;
var impCheckBinding = checkBinding;
var impCastByValue = castByValue;
var impTemplateSecurityContext = TemplateSecurityContext;
var impEMPTY_ARRAY = EMPTY_ARRAY;
var impEMPTY_MAP = EMPTY_MAP;

class Identifiers {
  static final appViewUtils = new CompileIdentifierMetadata(
      name: "appViewUtils",
      moduleUrl: 'asset:angular2/lib/src/core/linker/app_view_utils.dart');
  static final AppView = new CompileIdentifierMetadata(
      name: "AppView", moduleUrl: APP_VIEW_MODULE_URL);
  static final DebugAppView = new CompileIdentifierMetadata(
      name: "DebugAppView", moduleUrl: DEBUG_APP_VIEW_MODULE_URL);
  static final AppElement = new CompileIdentifierMetadata(
      name: "AppElement",
      moduleUrl: "asset:angular2/lib/src/core/linker/app_element.dart");
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
      name: 'ComponentFactory',
      moduleUrl: 'asset:angular2/lib/src/core/linker/component_factory.dart');
  static final RenderComponentType = new CompileIdentifierMetadata(
      name: "RenderComponentType",
      moduleUrl: "asset:angular2/lib/src/core/render/api.dart",
      runtime: impRenderComponentType);
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
  static final InjectorFactory = new CompileIdentifierMetadata(
      name: "CodegenInjectorFactory",
      moduleUrl: 'asset:angular2/lib/src/core/linker/'
          'injector_factory.dart',
      runtime: impCodegenInjectorFactory);
  static final CodegenInjector = new CompileIdentifierMetadata(
      name: "CodegenInjector",
      moduleUrl: '''asset:angular2/lib/src/core/linker/injector_factory.dart''',
      runtime: impCodegenInjector);
  static final ViewEncapsulation = new CompileIdentifierMetadata(
      name: "ViewEncapsulation",
      moduleUrl: "asset:angular2/lib/src/core/metadata/view.dart",
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
  static final Renderer = new CompileIdentifierMetadata(
      name: "Renderer",
      moduleUrl: "asset:angular2/lib/src/core/render/api.dart",
      runtime: impRenderer);
  static final SimpleChange = new CompileIdentifierMetadata(
      name: "SimpleChange", moduleUrl: CD_MODULE_URL, runtime: impSimpleChange);
  static final uninitialized = new CompileIdentifierMetadata(
      name: "uninitialized",
      moduleUrl: CD_MODULE_URL,
      runtime: impUninitialized);
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
  static final pureProxies = [
    null,
    new CompileIdentifierMetadata(
        name: "pureProxy1",
        moduleUrl: APP_VIEW_UTILS_MODULE_URL,
        runtime: pureProxy1),
    new CompileIdentifierMetadata(
        name: "pureProxy2",
        moduleUrl: APP_VIEW_UTILS_MODULE_URL,
        runtime: pureProxy2),
    new CompileIdentifierMetadata(
        name: "pureProxy3",
        moduleUrl: APP_VIEW_UTILS_MODULE_URL,
        runtime: pureProxy3),
    new CompileIdentifierMetadata(
        name: "pureProxy4",
        moduleUrl: APP_VIEW_UTILS_MODULE_URL,
        runtime: pureProxy4),
    new CompileIdentifierMetadata(
        name: "pureProxy5",
        moduleUrl: APP_VIEW_UTILS_MODULE_URL,
        runtime: pureProxy5),
    new CompileIdentifierMetadata(
        name: "pureProxy6",
        moduleUrl: APP_VIEW_UTILS_MODULE_URL,
        runtime: pureProxy6),
    new CompileIdentifierMetadata(
        name: "pureProxy7",
        moduleUrl: APP_VIEW_UTILS_MODULE_URL,
        runtime: pureProxy7),
    new CompileIdentifierMetadata(
        name: "pureProxy8",
        moduleUrl: APP_VIEW_UTILS_MODULE_URL,
        runtime: pureProxy8),
    new CompileIdentifierMetadata(
        name: "pureProxy9",
        moduleUrl: APP_VIEW_UTILS_MODULE_URL,
        runtime: pureProxy9),
    new CompileIdentifierMetadata(
        name: "pureProxy10",
        moduleUrl: APP_VIEW_UTILS_MODULE_URL,
        runtime: pureProxy10)
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
  static final HTML_ANCHOR_ELEMENT = new CompileIdentifierMetadata(
      name: "AnchorElement", moduleUrl: "dart:html");
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
}

CompileTokenMetadata identifierToken(CompileIdentifierMetadata identifier) {
  return new CompileTokenMetadata(identifier: identifier);
}
