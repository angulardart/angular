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
import "package:angular2/src/core/linker/element_ref.dart" show ElementRef;
import "package:angular2/src/core/linker/injector_factory.dart"
    show CodegenInjector, CodegenInjectorFactory;
import "package:angular2/src/core/linker/view_type.dart" show ViewType;
import "package:angular2/src/core/linker/view_utils.dart"
    show
        ViewUtils,
        interpolate,
        interpolate0,
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
import "package:angular2/src/core/metadata/view.dart" show ViewEncapsulation;
import "package:angular2/src/core/render/api.dart"
    show Renderer, RenderComponentType;
import "package:angular2/src/core/security.dart" show TemplateSecurityContext;

import "compile_metadata.dart"
    show CompileIdentifierMetadata, CompileTokenMetadata;
import "util.dart" show MODULE_SUFFIX;

var APP_VIEW_MODULE_URL =
    "asset:angular2/lib/src/core/linker/app_view" + MODULE_SUFFIX;
var VIEW_UTILS_MODULE_URL =
    "asset:angular2/lib/src/core/linker/view_utils" + MODULE_SUFFIX;
var CD_MODULE_URL =
    "asset:angular2/lib/src/core/change_detection/change_detection" +
        MODULE_SUFFIX;

// Reassign the imports to different variables so we can
// define static variables with the name of the import.

var impViewUtils = ViewUtils;
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
var impThrowOnChanges = () => ViewUtils.throwOnChanges;
var impInterpolate = interpolate;
var impCheckBinding = checkBinding;
var impCastByValue = castByValue;
var impTemplateSecurityContext = TemplateSecurityContext;
var impEMPTY_ARRAY = EMPTY_ARRAY;
var impEMPTY_MAP = EMPTY_MAP;

class Identifiers {
  static final ViewUtils = new CompileIdentifierMetadata(
      name: "ViewUtils",
      moduleUrl:
          "asset:angular2/lib/src/core/linker/view_utils" + MODULE_SUFFIX,
      runtime: impViewUtils);
  static final AppView = new CompileIdentifierMetadata(
      name: "AppView", moduleUrl: APP_VIEW_MODULE_URL);
  static final DebugAppView = new CompileIdentifierMetadata(
      name: "DebugAppView", moduleUrl: APP_VIEW_MODULE_URL);
  static final AppElement = new CompileIdentifierMetadata(
      name: "AppElement",
      moduleUrl: "asset:angular2/lib/src/core/linker/element" + MODULE_SUFFIX);
  static final ElementRef = new CompileIdentifierMetadata(
      name: "ElementRef",
      moduleUrl:
          "asset:angular2/lib/src/core/linker/element_ref" + MODULE_SUFFIX,
      runtime: impElementRef);
  static final ViewContainerRef = new CompileIdentifierMetadata(
      name: "ViewContainerRef",
      moduleUrl: "asset:angular2/lib/src/core/linker/view_container_ref" +
          MODULE_SUFFIX);
  static final ChangeDetectorRef = new CompileIdentifierMetadata(
      name: "ChangeDetectorRef",
      moduleUrl:
          "asset:angular2/lib/src/core/change_detection/change_detector_ref" +
              MODULE_SUFFIX,
      runtime: impChangeDetectorRef);
  static final ComponentFactory = new CompileIdentifierMetadata(
      name: 'ComponentFactory',
      moduleUrl:
          'asset:angular2/lib/src/core/linker/component_factory${MODULE_SUFFIX}');
  static final RenderComponentType = new CompileIdentifierMetadata(
      name: "RenderComponentType",
      moduleUrl: "asset:angular2/lib/src/core/render/api" + MODULE_SUFFIX,
      runtime: impRenderComponentType);
  static final QueryList = new CompileIdentifierMetadata(
      name: "QueryList",
      moduleUrl:
          "asset:angular2/lib/src/core/linker/query_list" + MODULE_SUFFIX);
  static final TemplateRef = new CompileIdentifierMetadata(
      name: "TemplateRef",
      moduleUrl:
          "asset:angular2/lib/src/core/linker/template_ref" + MODULE_SUFFIX);
  static final TemplateRef_ = new CompileIdentifierMetadata(
      name: "TemplateRef_",
      moduleUrl:
          "asset:angular2/lib/src/core/linker/template_ref" + MODULE_SUFFIX);
  static final ValueUnwrapper = new CompileIdentifierMetadata(
      name: "ValueUnwrapper",
      moduleUrl: CD_MODULE_URL,
      runtime: impValueUnwrapper);
  static final Injector = new CompileIdentifierMetadata(
      name: "Injector",
      moduleUrl: 'asset:angular2/lib/src/core/di/injector${ MODULE_SUFFIX}',
      runtime: impInjector);
  static final InjectorFactory = new CompileIdentifierMetadata(
      name: "CodegenInjectorFactory",
      moduleUrl: 'asset:angular2/lib/src/core/linker/'
          'injector_factory${ MODULE_SUFFIX}',
      runtime: impCodegenInjectorFactory);
  static final CodegenInjector = new CompileIdentifierMetadata(
      name: "CodegenInjector",
      moduleUrl:
          '''asset:angular2/lib/src/core/linker/injector_factory${ MODULE_SUFFIX}''',
      runtime: impCodegenInjector);
  static final ViewEncapsulation = new CompileIdentifierMetadata(
      name: "ViewEncapsulation",
      moduleUrl: "asset:angular2/lib/src/core/metadata/view" + MODULE_SUFFIX,
      runtime: impViewEncapsulation);
  static final ViewType = new CompileIdentifierMetadata(
      name: "ViewType",
      moduleUrl:
          '''asset:angular2/lib/src/core/linker/view_type${ MODULE_SUFFIX}''',
      runtime: impViewType);
  static final ChangeDetectionStrategy = new CompileIdentifierMetadata(
      name: "ChangeDetectionStrategy",
      moduleUrl: CD_MODULE_URL,
      runtime: impChangeDetectionStrategy);
  static final StaticNodeDebugInfo = new CompileIdentifierMetadata(
      name: "StaticNodeDebugInfo",
      moduleUrl:
          'asset:angular2/lib/src/core/linker/debug_context${ MODULE_SUFFIX}');
  static final DebugContext = new CompileIdentifierMetadata(
      name: "DebugContext",
      moduleUrl:
          'asset:angular2/lib/src/core/linker/debug_context${ MODULE_SUFFIX}');
  static final TemplateSecurityContext = new CompileIdentifierMetadata(
      name: 'TemplateSecurityContext',
      moduleUrl: 'asset:angular2/lib/src/core/security${ MODULE_SUFFIX}',
      runtime: impTemplateSecurityContext);
  static final Renderer = new CompileIdentifierMetadata(
      name: "Renderer",
      moduleUrl: "asset:angular2/lib/src/core/render/api" + MODULE_SUFFIX,
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
      moduleUrl: VIEW_UTILS_MODULE_URL,
      runtime: impCheckBinding);
  static final flattenNestedViewRenderNodes = new CompileIdentifierMetadata(
      name: "flattenNestedViewRenderNodes", moduleUrl: APP_VIEW_MODULE_URL);
  static final devModeEqual = new CompileIdentifierMetadata(
      name: "devModeEqual", moduleUrl: CD_MODULE_URL, runtime: impDevModeEqual);

  /// String interpolation where prefix,suffix are empty
  /// (most common case).
  static final throwOnChanges = new CompileIdentifierMetadata(
      name: "ViewUtils.throwOnChanges",
      moduleUrl: VIEW_UTILS_MODULE_URL,
      runtimeCallback: impThrowOnChanges);
  static final interpolate0 = new CompileIdentifierMetadata(
      name: "interpolate0",
      moduleUrl: VIEW_UTILS_MODULE_URL,
      runtime: impInterpolate0);
  static final interpolate = new CompileIdentifierMetadata(
      name: "interpolate",
      moduleUrl: VIEW_UTILS_MODULE_URL,
      runtime: impInterpolate);
  static final castByValue = new CompileIdentifierMetadata(
      name: "castByValue",
      moduleUrl: VIEW_UTILS_MODULE_URL,
      runtime: impCastByValue);
  static final EMPTY_ARRAY = new CompileIdentifierMetadata(
      name: "EMPTY_ARRAY",
      moduleUrl: VIEW_UTILS_MODULE_URL,
      runtime: impEMPTY_ARRAY);
  static final EMPTY_MAP = new CompileIdentifierMetadata(
      name: "EMPTY_MAP",
      moduleUrl: VIEW_UTILS_MODULE_URL,
      runtime: impEMPTY_MAP);
  static final pureProxies = [
    null,
    new CompileIdentifierMetadata(
        name: "pureProxy1",
        moduleUrl: VIEW_UTILS_MODULE_URL,
        runtime: pureProxy1),
    new CompileIdentifierMetadata(
        name: "pureProxy2",
        moduleUrl: VIEW_UTILS_MODULE_URL,
        runtime: pureProxy2),
    new CompileIdentifierMetadata(
        name: "pureProxy3",
        moduleUrl: VIEW_UTILS_MODULE_URL,
        runtime: pureProxy3),
    new CompileIdentifierMetadata(
        name: "pureProxy4",
        moduleUrl: VIEW_UTILS_MODULE_URL,
        runtime: pureProxy4),
    new CompileIdentifierMetadata(
        name: "pureProxy5",
        moduleUrl: VIEW_UTILS_MODULE_URL,
        runtime: pureProxy5),
    new CompileIdentifierMetadata(
        name: "pureProxy6",
        moduleUrl: VIEW_UTILS_MODULE_URL,
        runtime: pureProxy6),
    new CompileIdentifierMetadata(
        name: "pureProxy7",
        moduleUrl: VIEW_UTILS_MODULE_URL,
        runtime: pureProxy7),
    new CompileIdentifierMetadata(
        name: "pureProxy8",
        moduleUrl: VIEW_UTILS_MODULE_URL,
        runtime: pureProxy8),
    new CompileIdentifierMetadata(
        name: "pureProxy9",
        moduleUrl: VIEW_UTILS_MODULE_URL,
        runtime: pureProxy9),
    new CompileIdentifierMetadata(
        name: "pureProxy10",
        moduleUrl: VIEW_UTILS_MODULE_URL,
        runtime: pureProxy10)
  ];
}

CompileTokenMetadata identifierToken(CompileIdentifierMetadata identifier) {
  return new CompileTokenMetadata(identifier: identifier);
}
