import "compile_metadata.dart"
    show CompileIdentifierMetadata, CompileTokenMetadata;

const _angularLib = 'asset:angular/lib';

const _appViewModuleUrl = "$_angularLib/src/core/linker/app_view.dart";
const _appViewUtilsModuleUrl =
    "$_angularLib/src/core/linker/app_view_utils.dart";
const _cdModuleUrl =
    "$_angularLib/src/core/change_detection/change_detection.dart";
const _angularRootUrl = "package:angular/angular.dart";
const _ngIfUrl = "$_angularLib/src/common/directives/ng_if.dart";
const _ngForUrl = "$_angularLib/src/common/directives/ng_for.dart";
const _profileRuntimeModuleUrl = "$_angularLib/src/debug/profile_runtime.dart";
const _runtimeUtilsModuleUrl = "$_angularLib/src/runtime.dart";
final _debugInjectorModuleUrl = '$_angularLib/src/di/errors.dart';

/// A collection of methods for manipulating the DOM from generated code.
class DomHelpers {
  const DomHelpers._();

  static CompileIdentifierMetadata _of(String name) {
    return CompileIdentifierMetadata(
      name: name,
      moduleUrl: '$_angularLib/src/runtime/dom_helpers.dart',
    );
  }

  static final updateClassBinding = _of('updateClassBinding');
  static final updateClassBindingNonHtml = _of('updateClassBindingNonHtml');

  static final updateAttribute = _of('updateAttribute');
  static final updateAttributeNS = _of('updateAttributeNS');
  static final setAttribute = _of('setAttribute');
  static final setProperty = _of('setProperty');

  static final createText = _of('createText');
  static final appendText = _of('appendText');
  static final createAnchor = _of('createAnchor');
  static final appendAnchor = _of('appendAnchor');
  static final appendDiv = _of('appendDiv');
  static final appendSpan = _of('appendSpan');
  static final appendElement = _of('appendElement');
}

class SpecializedViews {
  const SpecializedViews._();

  static CompileIdentifierMetadata _of(String name) {
    return CompileIdentifierMetadata(
      name: name,
      moduleUrl: '$_angularLib/src/core/linker/$name.dart',
    );
  }

  static final componentView = _of('specializations/component');
  static final embeddedView = _of('specializations/embedded');
  static final hostView = _of('specializations/host');
}

class Identifiers {
  static final appViewUtils = CompileIdentifierMetadata<dynamic>(
      name: "appViewUtils", moduleUrl: _appViewUtilsModuleUrl);
  static final AppView = CompileIdentifierMetadata<dynamic>(
      name: "AppView", moduleUrl: _appViewModuleUrl);
  static final ViewContainer = CompileIdentifierMetadata<dynamic>(
      name: "ViewContainer",
      moduleUrl: "asset:angular/lib/src/core/linker/view_container.dart");
  static final ViewContainerToken = identifierToken(ViewContainer);
  static final ElementRef = CompileIdentifierMetadata<dynamic>(
      name: "ElementRef",
      moduleUrl: "asset:angular/lib/src/core/linker/element_ref.dart");
  static final ElementRefToken = identifierToken(ElementRef);
  static final ViewContainerRef = CompileIdentifierMetadata<dynamic>(
      name: "ViewContainerRef",
      moduleUrl: "asset:angular/lib/src/core/linker/view_container_ref.dart");
  static final ViewContainerRefToken =
      identifierToken(Identifiers.ViewContainerRef);
  static final ComponentLoader = CompileIdentifierMetadata<dynamic>(
      name: "ComponentLoader",
      moduleUrl: "asset:angular/lib/src/core/linker/component_loader.dart");
  static final ComponentLoaderToken = identifierToken(ComponentLoader);
  static final ChangeDetectorRef = CompileIdentifierMetadata<dynamic>(
      name: "ChangeDetectorRef",
      moduleUrl: 'asset:angular/lib/src/core/change_detection/'
          'change_detector_ref.dart');
  static final ChangeDetectorRefToken =
      identifierToken(Identifiers.ChangeDetectorRef);
  static final ComponentFactory = CompileIdentifierMetadata<dynamic>(
      name: 'ComponentFactory', moduleUrl: _angularRootUrl);
  static final DirectiveChangeDetector = CompileIdentifierMetadata<dynamic>(
      name: 'DirectiveChangeDetector',
      moduleUrl: 'asset:angular/lib/src/core/'
          'change_detection/directive_change_detector.dart');
  static final RenderComponentType = CompileIdentifierMetadata<dynamic>(
      name: "RenderComponentType",
      moduleUrl: "asset:angular/lib/src/core/render/api.dart");
  static final ComponentRef = CompileIdentifierMetadata<dynamic>(
      name: "ComponentRef", moduleUrl: _angularRootUrl);
  static final TemplateRef = CompileIdentifierMetadata<dynamic>(
      name: "TemplateRef",
      moduleUrl: "asset:angular/lib/src/core/linker/template_ref.dart");
  static final TemplateRefToken = identifierToken(Identifiers.TemplateRef);
  static final ValueUnwrapper = CompileIdentifierMetadata<dynamic>(
      name: "ValueUnwrapper", moduleUrl: _cdModuleUrl);
  static final Injector = CompileIdentifierMetadata<dynamic>(
      name: "Injector",
      moduleUrl: 'asset:angular/lib/src/di/injector/injector.dart');
  static final InjectorToken = identifierToken(Identifiers.Injector);
  static final ViewEncapsulation = CompileIdentifierMetadata<dynamic>(
      name: "ViewEncapsulation", moduleUrl: _angularRootUrl);
  static final ViewType = CompileIdentifierMetadata<dynamic>(
      name: "ViewType",
      moduleUrl: 'asset:angular/lib/src/core/linker/view_type.dart');
  static final ChangeDetectionStrategy = CompileIdentifierMetadata<dynamic>(
      name: "ChangeDetectionStrategy", moduleUrl: _cdModuleUrl);
  static final TemplateSecurityContext = CompileIdentifierMetadata<dynamic>(
      name: 'TemplateSecurityContext',
      moduleUrl: 'asset:angular/lib/src/core/security.dart');
  static final SimpleChange = CompileIdentifierMetadata<dynamic>(
      name: "SimpleChange", moduleUrl: _cdModuleUrl);
  static final ChangeDetectorState = CompileIdentifierMetadata<dynamic>(
      name: "ChangeDetectorState", moduleUrl: _cdModuleUrl);
  static final checkBinding = CompileIdentifierMetadata<dynamic>(
      name: "checkBinding", moduleUrl: _appViewUtilsModuleUrl);
  static final createText = CompileIdentifierMetadata(
      name: "createText", moduleUrl: _appViewModuleUrl);
  static final devModeEqual = CompileIdentifierMetadata<dynamic>(
      name: "devModeEqual", moduleUrl: _cdModuleUrl);
  static final identical =
      CompileIdentifierMetadata<dynamic>(name: "identical");
  static final profileSetup = CompileIdentifierMetadata<dynamic>(
      name: "profileSetup", moduleUrl: _profileRuntimeModuleUrl);
  static final profileMarkStart = CompileIdentifierMetadata<dynamic>(
      name: "profileMarkStart", moduleUrl: _profileRuntimeModuleUrl);
  static final profileMarkEnd = CompileIdentifierMetadata<dynamic>(
      name: "profileMarkEnd", moduleUrl: _profileRuntimeModuleUrl);

  static final throwOnChanges = CompileIdentifierMetadata<dynamic>(
      name: "AppViewUtils.throwOnChanges", moduleUrl: _appViewUtilsModuleUrl);
  static final isDevMode = CompileIdentifierMetadata<dynamic>(
      name: "isDevMode", moduleUrl: _runtimeUtilsModuleUrl);
  static final unsafeCast = CompileIdentifierMetadata<dynamic>(
      name: "unsafeCast", moduleUrl: _runtimeUtilsModuleUrl);
  static final debugInjectorEnter = CompileIdentifierMetadata<dynamic>(
      name: "debugInjectorEnter", moduleUrl: _debugInjectorModuleUrl);
  static final debugInjectorLeave = CompileIdentifierMetadata<dynamic>(
      name: "debugInjectorLeave", moduleUrl: _debugInjectorModuleUrl);
  static final debugInjectorWrap = CompileIdentifierMetadata<dynamic>(
      name: "debugInjectorWrap", moduleUrl: _debugInjectorModuleUrl);

  /// String interpolation where prefix,suffix are empty
  /// (most common case).
  static final interpolateString = <CompileIdentifierMetadata>[
    CompileIdentifierMetadata<dynamic>(
        name: "interpolateString0", moduleUrl: _appViewUtilsModuleUrl),
    CompileIdentifierMetadata<dynamic>(
        name: "interpolateString1", moduleUrl: _appViewUtilsModuleUrl),
    CompileIdentifierMetadata<dynamic>(
        name: "interpolateString2", moduleUrl: _appViewUtilsModuleUrl),
    CompileIdentifierMetadata<dynamic>(
        name: "interpolateString3", moduleUrl: _appViewUtilsModuleUrl),
    CompileIdentifierMetadata<dynamic>(
        name: "interpolateString4", moduleUrl: _appViewUtilsModuleUrl),
    CompileIdentifierMetadata<dynamic>(
        name: "interpolateString5", moduleUrl: _appViewUtilsModuleUrl),
    CompileIdentifierMetadata<dynamic>(
        name: "interpolateString6", moduleUrl: _appViewUtilsModuleUrl),
    CompileIdentifierMetadata<dynamic>(
        name: "interpolateString7", moduleUrl: _appViewUtilsModuleUrl),
    CompileIdentifierMetadata<dynamic>(
        name: "interpolateString8", moduleUrl: _appViewUtilsModuleUrl),
    CompileIdentifierMetadata<dynamic>(
        name: "interpolateString9", moduleUrl: _appViewUtilsModuleUrl),
  ];

  static final interpolate = <CompileIdentifierMetadata>[
    CompileIdentifierMetadata<dynamic>(
        name: "interpolate0", moduleUrl: _appViewUtilsModuleUrl),
    CompileIdentifierMetadata<dynamic>(
        name: "interpolate1", moduleUrl: _appViewUtilsModuleUrl),
    CompileIdentifierMetadata<dynamic>(
        name: "interpolate2", moduleUrl: _appViewUtilsModuleUrl),
    CompileIdentifierMetadata<dynamic>(
        name: "interpolate3", moduleUrl: _appViewUtilsModuleUrl),
    CompileIdentifierMetadata<dynamic>(
        name: "interpolate4", moduleUrl: _appViewUtilsModuleUrl),
    CompileIdentifierMetadata<dynamic>(
        name: "interpolate5", moduleUrl: _appViewUtilsModuleUrl),
    CompileIdentifierMetadata<dynamic>(
        name: "interpolate6", moduleUrl: _appViewUtilsModuleUrl),
    CompileIdentifierMetadata<dynamic>(
        name: "interpolate7", moduleUrl: _appViewUtilsModuleUrl),
    CompileIdentifierMetadata<dynamic>(
        name: "interpolate8", moduleUrl: _appViewUtilsModuleUrl),
    CompileIdentifierMetadata<dynamic>(
        name: "interpolate9", moduleUrl: _appViewUtilsModuleUrl),
  ];
  static final createTrustedHtml = CompileIdentifierMetadata(
      name: 'createTrustedHtml', moduleUrl: _appViewUtilsModuleUrl);
  static final flattenNodes = CompileIdentifierMetadata<dynamic>(
      name: "flattenNodes", moduleUrl: _appViewUtilsModuleUrl);
  static final firstOrNull = CompileIdentifierMetadata<dynamic>(
      name: "firstOrNull", moduleUrl: _appViewUtilsModuleUrl);
  static final EMPTY_ARRAY = CompileIdentifierMetadata<dynamic>(
      name: "EMPTY_ARRAY", moduleUrl: _appViewUtilsModuleUrl);
  static final EMPTY_MAP = CompileIdentifierMetadata<dynamic>(
      name: "EMPTY_MAP", moduleUrl: _appViewUtilsModuleUrl);
  static final NG_IF_DIRECTIVE =
      CompileIdentifierMetadata<dynamic>(name: "NgIf", moduleUrl: _ngIfUrl);
  static final NG_FOR_DIRECTIVE =
      CompileIdentifierMetadata<dynamic>(name: "NgFor", moduleUrl: _ngForUrl);
  static final pureProxies = [
    null,
    CompileIdentifierMetadata<dynamic>(
        name: "pureProxy1", moduleUrl: _appViewUtilsModuleUrl),
    CompileIdentifierMetadata<dynamic>(
        name: "pureProxy2", moduleUrl: _appViewUtilsModuleUrl),
    CompileIdentifierMetadata<dynamic>(
        name: "pureProxy3", moduleUrl: _appViewUtilsModuleUrl),
    CompileIdentifierMetadata<dynamic>(
        name: "pureProxy4", moduleUrl: _appViewUtilsModuleUrl),
    CompileIdentifierMetadata<dynamic>(
        name: "pureProxy5", moduleUrl: _appViewUtilsModuleUrl),
    CompileIdentifierMetadata<dynamic>(
        name: "pureProxy6", moduleUrl: _appViewUtilsModuleUrl),
    CompileIdentifierMetadata<dynamic>(
        name: "pureProxy7", moduleUrl: _appViewUtilsModuleUrl),
    CompileIdentifierMetadata<dynamic>(
        name: "pureProxy8", moduleUrl: _appViewUtilsModuleUrl),
    CompileIdentifierMetadata<dynamic>(
        name: "pureProxy9", moduleUrl: _appViewUtilsModuleUrl),
    CompileIdentifierMetadata<dynamic>(
        name: "pureProxy10", moduleUrl: _appViewUtilsModuleUrl)
  ];
  // Runtime is initialized by output interpreter. Compiler executes in VM and
  // can't import dart:html to initialize here.
  static var HTML_COMMENT_NODE = CompileIdentifierMetadata<dynamic>(
      name: "Comment", moduleUrl: "dart:html");
  static var HTML_TEXT_NODE =
      CompileIdentifierMetadata<dynamic>(name: "Text", moduleUrl: "dart:html");
  static var HTML_DOCUMENT = CompileIdentifierMetadata<dynamic>(
      name: "document", moduleUrl: "dart:html");
  static final HTML_DOCUMENT_FRAGMENT = CompileIdentifierMetadata(
      name: 'DocumentFragment', moduleUrl: 'dart:html');
  static final HTML_ELEMENT = CompileIdentifierMetadata<dynamic>(
      name: "Element", moduleUrl: "dart:html");
  static final ElementToken = identifierToken(HTML_ELEMENT);
  static final HTML_HTML_ELEMENT = CompileIdentifierMetadata<dynamic>(
      name: "HtmlElement", moduleUrl: "dart:html");
  static final HtmlElementToken = identifierToken(HTML_HTML_ELEMENT);
  static final SVG_SVG_ELEMENT = CompileIdentifierMetadata<dynamic>(
      name: "SvgSvgElement", moduleUrl: "dart:svg");
  static final SVG_ELEMENT = CompileIdentifierMetadata<dynamic>(
      name: "SvgElement", moduleUrl: "dart:svg");
  static final HTML_ANCHOR_ELEMENT = CompileIdentifierMetadata<dynamic>(
      name: "AnchorElement", moduleUrl: "dart:html");
  static final HTML_DIV_ELEMENT = CompileIdentifierMetadata<dynamic>(
      name: "DivElement", moduleUrl: "dart:html");
  static final HTML_AREA_ELEMENT = CompileIdentifierMetadata<dynamic>(
      name: "AreaElement", moduleUrl: "dart:html");
  static final HTML_AUDIO_ELEMENT = CompileIdentifierMetadata<dynamic>(
      name: "AudioElement", moduleUrl: "dart:html");
  static final HTML_BUTTON_ELEMENT = CompileIdentifierMetadata<dynamic>(
      name: "ButtonElement", moduleUrl: "dart:html");
  static final HTML_CANVAS_ELEMENT = CompileIdentifierMetadata<dynamic>(
      name: "CanvasElement", moduleUrl: "dart:html");
  static final HTML_FORM_ELEMENT = CompileIdentifierMetadata<dynamic>(
      name: "FormElement", moduleUrl: "dart:html");
  static final HTML_IFRAME_ELEMENT = CompileIdentifierMetadata<dynamic>(
      name: "IFrameElement", moduleUrl: "dart:html");
  static final HTML_IMAGE_ELEMENT = CompileIdentifierMetadata<dynamic>(
      name: "ImageElement", moduleUrl: "dart:html");
  static final HTML_INPUT_ELEMENT = CompileIdentifierMetadata<dynamic>(
      name: "InputElement", moduleUrl: "dart:html");
  static final HTML_TEXTAREA_ELEMENT = CompileIdentifierMetadata<dynamic>(
      name: "TextAreaElement", moduleUrl: "dart:html");
  static final HTML_MEDIA_ELEMENT = CompileIdentifierMetadata<dynamic>(
      name: "MediaElement", moduleUrl: "dart:html");
  static final HTML_MENU_ELEMENT = CompileIdentifierMetadata<dynamic>(
      name: "MenuElement", moduleUrl: "dart:html");
  static final HTML_NODE_TREE_SANITIZER = CompileIdentifierMetadata(
      name: 'NodeTreeSanitizer', moduleUrl: 'dart:html');
  static final HTML_OPTION_ELEMENT = CompileIdentifierMetadata<dynamic>(
      name: "OptionElement", moduleUrl: "dart:html");
  static final HTML_OLIST_ELEMENT = CompileIdentifierMetadata<dynamic>(
      name: "OListElement", moduleUrl: "dart:html");
  static final HTML_SELECT_ELEMENT = CompileIdentifierMetadata<dynamic>(
      name: "SelectElement", moduleUrl: "dart:html");
  static final HTML_TABLE_ELEMENT = CompileIdentifierMetadata<dynamic>(
      name: "TableElement", moduleUrl: "dart:html");
  static final HTML_TABLE_ROW_ELEMENT = CompileIdentifierMetadata<dynamic>(
      name: "TableRowElement", moduleUrl: "dart:html");
  static final HTML_TABLE_COL_ELEMENT = CompileIdentifierMetadata<dynamic>(
      name: "TableColElement", moduleUrl: "dart:html");
  static final HTML_ULIST_ELEMENT = CompileIdentifierMetadata<dynamic>(
      name: "UListElement", moduleUrl: "dart:html");
  static final HTML_EVENT =
      CompileIdentifierMetadata<dynamic>(name: "Event", moduleUrl: "dart:html");
  static final HTML_NODE =
      CompileIdentifierMetadata<dynamic>(name: "Node", moduleUrl: "dart:html");

  /// A class used for message internationalization.
  static final Intl = CompileIdentifierMetadata(
    name: 'Intl',
    moduleUrl: 'package:intl/intl.dart',
  );

  static final dart2JsNoInline = CompileIdentifierMetadata(
    name: 'noInline',
    moduleUrl: 'package:meta/dart2js.dart',
  );

  static final dartCoreOverride = CompileIdentifierMetadata(
    name: 'override',
  );
}

CompileTokenMetadata identifierToken(CompileIdentifierMetadata identifier) {
  return CompileTokenMetadata(identifier: identifier);
}
