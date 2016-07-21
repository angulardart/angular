library angular2.src.compiler.identifiers;

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
import "package:angular2/src/core/linker.dart" show QueryList;
import "package:angular2/src/core/linker/debug_context.dart"
    show StaticNodeDebugInfo, DebugContext;
import "package:angular2/src/core/linker/element.dart" show AppElement;
import "package:angular2/src/core/linker/element_ref.dart" show ElementRef;
import "package:angular2/src/core/linker/injector_factory.dart"
    show CodegenInjector, CodegenInjectorFactory;
import "package:angular2/src/core/linker/template_ref.dart"
    show TemplateRef, TemplateRef_;
import "package:angular2/src/core/linker/view.dart" show AppView, DebugAppView;
import "package:angular2/src/core/linker/view_container_ref.dart"
    show ViewContainerRef;
import "package:angular2/src/core/linker/view_type.dart" show ViewType;
import "package:angular2/src/core/linker/view_utils.dart"
    show
        ViewUtils,
        flattenNestedViewRenderNodes,
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
    "asset:angular2/lib/src/core/linker/view" + MODULE_SUFFIX;
var VIEW_UTILS_MODULE_URL =
    "asset:angular2/lib/src/core/linker/view_utils" + MODULE_SUFFIX;
var CD_MODULE_URL =
    "asset:angular2/lib/src/core/change_detection/change_detection" +
        MODULE_SUFFIX;
// Reassign the imports to different variables so we can

// define static variables with the name of the import.

// (only needed for Dart).
var impViewUtils = ViewUtils;
var impAppView = AppView;
var impDebugAppView = DebugAppView;
var impDebugContext = DebugContext;
var impAppElement = AppElement;
var impElementRef = ElementRef;
var impViewContainerRef = ViewContainerRef;
var impChangeDetectorRef = ChangeDetectorRef;
var impRenderComponentType = RenderComponentType;
var impQueryList = QueryList;
var impTemplateRef = TemplateRef;
var impTemplateRef_ = TemplateRef_;
var impValueUnwrapper = ValueUnwrapper;
var impInjector = Injector;
var impCodegenInjector = CodegenInjector;
var impCodegenInjectorFactory = CodegenInjectorFactory;
var impViewEncapsulation = ViewEncapsulation;
var impViewType = ViewType;
var impChangeDetectionStrategy = ChangeDetectionStrategy;
var impStaticNodeDebugInfo = StaticNodeDebugInfo;
var impRenderer = Renderer;
var impSimpleChange = SimpleChange;
var impUninitialized = uninitialized;
var impChangeDetectorState = ChangeDetectorState;
var impFlattenNestedViewRenderNodes = flattenNestedViewRenderNodes;
var impDevModeEqual = devModeEqual;
var impInterpolate0 = interpolate0;
var impInterpolate = interpolate;
var impCheckBinding = checkBinding;
var impCastByValue = castByValue;
var impTemplateSecurityContext = TemplateSecurityContext;
var impEMPTY_ARRAY = EMPTY_ARRAY;
var impEMPTY_MAP = EMPTY_MAP;

class Identifiers {
  static var ViewUtils = new CompileIdentifierMetadata(
      name: "ViewUtils",
      moduleUrl:
          "asset:angular2/lib/src/core/linker/view_utils" + MODULE_SUFFIX,
      runtime: impViewUtils);
  static var AppView = new CompileIdentifierMetadata(
      name: "AppView", moduleUrl: APP_VIEW_MODULE_URL, runtime: impAppView);
  static var DebugAppView = new CompileIdentifierMetadata(
      name: "DebugAppView",
      moduleUrl: APP_VIEW_MODULE_URL,
      runtime: impDebugAppView);
  static var AppElement = new CompileIdentifierMetadata(
      name: "AppElement",
      moduleUrl: "asset:angular2/lib/src/core/linker/element" + MODULE_SUFFIX,
      runtime: impAppElement);
  static var ElementRef = new CompileIdentifierMetadata(
      name: "ElementRef",
      moduleUrl:
          "asset:angular2/lib/src/core/linker/element_ref" + MODULE_SUFFIX,
      runtime: impElementRef);
  static var ViewContainerRef = new CompileIdentifierMetadata(
      name: "ViewContainerRef",
      moduleUrl: "asset:angular2/lib/src/core/linker/view_container_ref" +
          MODULE_SUFFIX,
      runtime: impViewContainerRef);
  static var ChangeDetectorRef = new CompileIdentifierMetadata(
      name: "ChangeDetectorRef",
      moduleUrl:
          "asset:angular2/lib/src/core/change_detection/change_detector_ref" +
              MODULE_SUFFIX,
      runtime: impChangeDetectorRef);
  static var RenderComponentType = new CompileIdentifierMetadata(
      name: "RenderComponentType",
      moduleUrl: "asset:angular2/lib/src/core/render/api" + MODULE_SUFFIX,
      runtime: impRenderComponentType);
  static var QueryList = new CompileIdentifierMetadata(
      name: "QueryList",
      moduleUrl:
          "asset:angular2/lib/src/core/linker/query_list" + MODULE_SUFFIX,
      runtime: impQueryList);
  static var TemplateRef = new CompileIdentifierMetadata(
      name: "TemplateRef",
      moduleUrl:
          "asset:angular2/lib/src/core/linker/template_ref" + MODULE_SUFFIX,
      runtime: impTemplateRef);
  static var TemplateRef_ = new CompileIdentifierMetadata(
      name: "TemplateRef_",
      moduleUrl:
          "asset:angular2/lib/src/core/linker/template_ref" + MODULE_SUFFIX,
      runtime: impTemplateRef_);
  static var ValueUnwrapper = new CompileIdentifierMetadata(
      name: "ValueUnwrapper",
      moduleUrl: CD_MODULE_URL,
      runtime: impValueUnwrapper);
  static var Injector = new CompileIdentifierMetadata(
      name: "Injector",
      moduleUrl: '''asset:angular2/lib/src/core/di/injector${ MODULE_SUFFIX}''',
      runtime: impInjector);
  static var InjectorFactory = new CompileIdentifierMetadata(
      name: "CodegenInjectorFactory",
      moduleUrl:
          '''asset:angular2/lib/src/core/linker/injector_factory${ MODULE_SUFFIX}''',
      runtime: impCodegenInjectorFactory);
  static var CodegenInjector = new CompileIdentifierMetadata(
      name: "CodegenInjector",
      moduleUrl:
          '''asset:angular2/lib/src/core/linker/injector_factory${ MODULE_SUFFIX}''',
      runtime: impCodegenInjector);
  static var ViewEncapsulation = new CompileIdentifierMetadata(
      name: "ViewEncapsulation",
      moduleUrl: "asset:angular2/lib/src/core/metadata/view" + MODULE_SUFFIX,
      runtime: impViewEncapsulation);
  static var ViewType = new CompileIdentifierMetadata(
      name: "ViewType",
      moduleUrl:
          '''asset:angular2/lib/src/core/linker/view_type${ MODULE_SUFFIX}''',
      runtime: impViewType);
  static var ChangeDetectionStrategy = new CompileIdentifierMetadata(
      name: "ChangeDetectionStrategy",
      moduleUrl: CD_MODULE_URL,
      runtime: impChangeDetectionStrategy);
  static var StaticNodeDebugInfo = new CompileIdentifierMetadata(
      name: "StaticNodeDebugInfo",
      moduleUrl:
          '''asset:angular2/lib/src/core/linker/debug_context${ MODULE_SUFFIX}''',
      runtime: impStaticNodeDebugInfo);
  static var DebugContext = new CompileIdentifierMetadata(
      name: "DebugContext",
      moduleUrl:
          '''asset:angular2/lib/src/core/linker/debug_context${ MODULE_SUFFIX}''',
      runtime: impDebugContext);
  static var TemplateSecurityContext = new CompileIdentifierMetadata(
      name: 'TemplateSecurityContext',
      moduleUrl: 'asset:angular2/lib/src/core/security${ MODULE_SUFFIX}',
      runtime: impTemplateSecurityContext);
  static var Renderer = new CompileIdentifierMetadata(
      name: "Renderer",
      moduleUrl: "asset:angular2/lib/src/core/render/api" + MODULE_SUFFIX,
      runtime: impRenderer);
  static var SimpleChange = new CompileIdentifierMetadata(
      name: "SimpleChange", moduleUrl: CD_MODULE_URL, runtime: impSimpleChange);
  static var uninitialized = new CompileIdentifierMetadata(
      name: "uninitialized",
      moduleUrl: CD_MODULE_URL,
      runtime: impUninitialized);
  static var ChangeDetectorState = new CompileIdentifierMetadata(
      name: "ChangeDetectorState",
      moduleUrl: CD_MODULE_URL,
      runtime: impChangeDetectorState);
  static var checkBinding = new CompileIdentifierMetadata(
      name: "checkBinding",
      moduleUrl: VIEW_UTILS_MODULE_URL,
      runtime: impCheckBinding);
  static var flattenNestedViewRenderNodes = new CompileIdentifierMetadata(
      name: "flattenNestedViewRenderNodes",
      moduleUrl: VIEW_UTILS_MODULE_URL,
      runtime: impFlattenNestedViewRenderNodes);
  static var devModeEqual = new CompileIdentifierMetadata(
      name: "devModeEqual", moduleUrl: CD_MODULE_URL, runtime: impDevModeEqual);

  /// String interpolation where prefix,suffix are empty
  /// (most common case).
  static var interpolate0 = new CompileIdentifierMetadata(
      name: "interpolate0",
      moduleUrl: VIEW_UTILS_MODULE_URL,
      runtime: impInterpolate0);
  static var interpolate = new CompileIdentifierMetadata(
      name: "interpolate",
      moduleUrl: VIEW_UTILS_MODULE_URL,
      runtime: impInterpolate);
  static var castByValue = new CompileIdentifierMetadata(
      name: "castByValue",
      moduleUrl: VIEW_UTILS_MODULE_URL,
      runtime: impCastByValue);
  static var EMPTY_ARRAY = new CompileIdentifierMetadata(
      name: "EMPTY_ARRAY",
      moduleUrl: VIEW_UTILS_MODULE_URL,
      runtime: impEMPTY_ARRAY);
  static var EMPTY_MAP = new CompileIdentifierMetadata(
      name: "EMPTY_MAP",
      moduleUrl: VIEW_UTILS_MODULE_URL,
      runtime: impEMPTY_MAP);
  static var pureProxies = [
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
