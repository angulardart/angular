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
const _textBindingModuleUrl = "$_angularLib/src/runtime/text_binding.dart";
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

class StyleEncapsulation {
  const StyleEncapsulation._();

  static CompileIdentifierMetadata _of(String name) {
    return CompileIdentifierMetadata(
      name: name,
      moduleUrl: '$_angularLib/src/core/linker/style_encapsulation.dart',
    );
  }

  static final componentStyles = _of('ComponentStyles');
  static final componentStylesScoped = _of('ComponentStyles.scoped');
  static final componentStylesUnscoped = _of('ComponentStyles.unscoped');
}

class Identifiers {
  static final appViewUtils = CompileIdentifierMetadata(
      name: "appViewUtils", moduleUrl: _appViewUtilsModuleUrl);
  static final AppView =
      CompileIdentifierMetadata(name: "AppView", moduleUrl: _appViewModuleUrl);
  static final ViewContainer = CompileIdentifierMetadata(
      name: "ViewContainer",
      moduleUrl: "asset:angular/lib/src/core/linker/view_container.dart");
  static final ViewContainerToken = identifierToken(ViewContainer);
  static final ElementRef = CompileIdentifierMetadata(
      name: "ElementRef",
      moduleUrl: "asset:angular/lib/src/core/linker/element_ref.dart");
  static final ElementRefToken = identifierToken(ElementRef);
  static final ViewContainerRef = CompileIdentifierMetadata(
      name: "ViewContainerRef",
      moduleUrl: "asset:angular/lib/src/core/linker/view_container_ref.dart");
  static final ViewContainerRefToken =
      identifierToken(Identifiers.ViewContainerRef);
  static final ComponentLoader = CompileIdentifierMetadata(
      name: "ComponentLoader",
      moduleUrl: "asset:angular/lib/src/core/linker/component_loader.dart");
  static final ComponentLoaderToken = identifierToken(ComponentLoader);
  static final ChangeDetectorRef = CompileIdentifierMetadata(
      name: "ChangeDetectorRef",
      moduleUrl: 'asset:angular/lib/src/core/change_detection/'
          'change_detector_ref.dart');
  static final ChangeDetectorRefToken =
      identifierToken(Identifiers.ChangeDetectorRef);
  static final ComponentFactory = CompileIdentifierMetadata(
      name: 'ComponentFactory', moduleUrl: _angularRootUrl);
  static final DirectiveChangeDetector = CompileIdentifierMetadata(
      name: 'DirectiveChangeDetector',
      moduleUrl: 'asset:angular/lib/src/core/'
          'change_detection/directive_change_detector.dart');
  static final RenderComponentType = CompileIdentifierMetadata(
      name: "RenderComponentType",
      moduleUrl: "asset:angular/lib/src/core/render/api.dart");
  static final ComponentRef = CompileIdentifierMetadata(
      name: "ComponentRef", moduleUrl: _angularRootUrl);
  static final TemplateRef = CompileIdentifierMetadata(
      name: "TemplateRef",
      moduleUrl: "asset:angular/lib/src/core/linker/template_ref.dart");
  static final TemplateRefToken = identifierToken(Identifiers.TemplateRef);
  static final ValueUnwrapper = CompileIdentifierMetadata(
      name: "ValueUnwrapper", moduleUrl: _cdModuleUrl);
  static final Injector = CompileIdentifierMetadata(
      name: "Injector",
      moduleUrl: 'asset:angular/lib/src/di/injector/injector.dart');
  static final InjectorToken = identifierToken(Identifiers.Injector);
  static final ViewEncapsulation = CompileIdentifierMetadata(
      name: "ViewEncapsulation", moduleUrl: _angularRootUrl);
  static final ViewType = CompileIdentifierMetadata(
      name: "ViewType",
      moduleUrl: 'asset:angular/lib/src/core/linker/view_type.dart');
  static final ChangeDetectionStrategy = CompileIdentifierMetadata(
      name: "ChangeDetectionStrategy", moduleUrl: _cdModuleUrl);
  static final TemplateSecurityContext = CompileIdentifierMetadata(
      name: 'TemplateSecurityContext',
      moduleUrl: 'asset:angular/lib/src/core/security.dart');
  static final SimpleChange =
      CompileIdentifierMetadata(name: "SimpleChange", moduleUrl: _cdModuleUrl);
  static final ChangeDetectorState = CompileIdentifierMetadata(
      name: "ChangeDetectorState", moduleUrl: _cdModuleUrl);
  static final checkBinding = CompileIdentifierMetadata(
      name: "checkBinding", moduleUrl: _appViewUtilsModuleUrl);
  static final createText = CompileIdentifierMetadata(
      name: "createText", moduleUrl: _appViewModuleUrl);
  static final devModeEqual =
      CompileIdentifierMetadata(name: "devModeEqual", moduleUrl: _cdModuleUrl);
  static final identical = CompileIdentifierMetadata(name: "identical");
  static final profileSetup = CompileIdentifierMetadata(
      name: "profileSetup", moduleUrl: _profileRuntimeModuleUrl);
  static final profileMarkStart = CompileIdentifierMetadata(
      name: "profileMarkStart", moduleUrl: _profileRuntimeModuleUrl);
  static final profileMarkEnd = CompileIdentifierMetadata(
      name: "profileMarkEnd", moduleUrl: _profileRuntimeModuleUrl);

  static final throwOnChanges = CompileIdentifierMetadata(
      name: "AppViewUtils.throwOnChanges", moduleUrl: _appViewUtilsModuleUrl);
  static final isDevMode = CompileIdentifierMetadata(
      name: "isDevMode", moduleUrl: _runtimeUtilsModuleUrl);
  static final unsafeCast = CompileIdentifierMetadata(
      name: "unsafeCast", moduleUrl: _runtimeUtilsModuleUrl);
  static final debugInjectorEnter = CompileIdentifierMetadata(
      name: "debugInjectorEnter", moduleUrl: _debugInjectorModuleUrl);
  static final debugInjectorLeave = CompileIdentifierMetadata(
      name: "debugInjectorLeave", moduleUrl: _debugInjectorModuleUrl);
  static final debugInjectorWrap = CompileIdentifierMetadata(
      name: "debugInjectorWrap", moduleUrl: _debugInjectorModuleUrl);

  static final TextBinding = CompileIdentifierMetadata(
      name: "TextBinding", moduleUrl: _textBindingModuleUrl);

  static final createTextBinding = CompileIdentifierMetadata(
      name: "createTextBinding", moduleUrl: _textBindingModuleUrl);

  /// String interpolation where prefix,suffix are empty
  /// (most common case).
  static final interpolateString = <CompileIdentifierMetadata>[
    CompileIdentifierMetadata(
        name: "interpolateString0", moduleUrl: _appViewUtilsModuleUrl),
    CompileIdentifierMetadata(
        name: "interpolateString1", moduleUrl: _appViewUtilsModuleUrl),
    CompileIdentifierMetadata(
        name: "interpolateString2", moduleUrl: _appViewUtilsModuleUrl),
    CompileIdentifierMetadata(
        name: "interpolateString3", moduleUrl: _appViewUtilsModuleUrl),
    CompileIdentifierMetadata(
        name: "interpolateString4", moduleUrl: _appViewUtilsModuleUrl),
    CompileIdentifierMetadata(
        name: "interpolateString5", moduleUrl: _appViewUtilsModuleUrl),
    CompileIdentifierMetadata(
        name: "interpolateString6", moduleUrl: _appViewUtilsModuleUrl),
    CompileIdentifierMetadata(
        name: "interpolateString7", moduleUrl: _appViewUtilsModuleUrl),
    CompileIdentifierMetadata(
        name: "interpolateString8", moduleUrl: _appViewUtilsModuleUrl),
    CompileIdentifierMetadata(
        name: "interpolateString9", moduleUrl: _appViewUtilsModuleUrl),
  ];

  static final interpolate = <CompileIdentifierMetadata>[
    CompileIdentifierMetadata(
        name: "interpolate0", moduleUrl: _appViewUtilsModuleUrl),
    CompileIdentifierMetadata(
        name: "interpolate1", moduleUrl: _appViewUtilsModuleUrl),
    CompileIdentifierMetadata(
        name: "interpolate2", moduleUrl: _appViewUtilsModuleUrl),
    CompileIdentifierMetadata(
        name: "interpolate3", moduleUrl: _appViewUtilsModuleUrl),
    CompileIdentifierMetadata(
        name: "interpolate4", moduleUrl: _appViewUtilsModuleUrl),
    CompileIdentifierMetadata(
        name: "interpolate5", moduleUrl: _appViewUtilsModuleUrl),
    CompileIdentifierMetadata(
        name: "interpolate6", moduleUrl: _appViewUtilsModuleUrl),
    CompileIdentifierMetadata(
        name: "interpolate7", moduleUrl: _appViewUtilsModuleUrl),
    CompileIdentifierMetadata(
        name: "interpolate8", moduleUrl: _appViewUtilsModuleUrl),
    CompileIdentifierMetadata(
        name: "interpolate9", moduleUrl: _appViewUtilsModuleUrl),
  ];
  static final createTrustedHtml = CompileIdentifierMetadata(
      name: 'createTrustedHtml', moduleUrl: _appViewUtilsModuleUrl);
  static final flattenNodes = CompileIdentifierMetadata(
      name: "flattenNodes", moduleUrl: _appViewUtilsModuleUrl);
  static final firstOrNull = CompileIdentifierMetadata(
      name: "firstOrNull", moduleUrl: _appViewUtilsModuleUrl);
  static final EMPTY_ARRAY = CompileIdentifierMetadata(
      name: "EMPTY_ARRAY", moduleUrl: _appViewUtilsModuleUrl);
  static final EMPTY_MAP = CompileIdentifierMetadata(
      name: "EMPTY_MAP", moduleUrl: _appViewUtilsModuleUrl);
  static final NG_IF_DIRECTIVE =
      CompileIdentifierMetadata(name: "NgIf", moduleUrl: _ngIfUrl);
  static final NG_FOR_DIRECTIVE =
      CompileIdentifierMetadata(name: "NgFor", moduleUrl: _ngForUrl);
  static final pureProxies = [
    null,
    CompileIdentifierMetadata(
        name: "pureProxy1", moduleUrl: _appViewUtilsModuleUrl),
    CompileIdentifierMetadata(
        name: "pureProxy2", moduleUrl: _appViewUtilsModuleUrl),
    CompileIdentifierMetadata(
        name: "pureProxy3", moduleUrl: _appViewUtilsModuleUrl),
    CompileIdentifierMetadata(
        name: "pureProxy4", moduleUrl: _appViewUtilsModuleUrl),
    CompileIdentifierMetadata(
        name: "pureProxy5", moduleUrl: _appViewUtilsModuleUrl),
    CompileIdentifierMetadata(
        name: "pureProxy6", moduleUrl: _appViewUtilsModuleUrl),
    CompileIdentifierMetadata(
        name: "pureProxy7", moduleUrl: _appViewUtilsModuleUrl),
    CompileIdentifierMetadata(
        name: "pureProxy8", moduleUrl: _appViewUtilsModuleUrl),
    CompileIdentifierMetadata(
        name: "pureProxy9", moduleUrl: _appViewUtilsModuleUrl),
    CompileIdentifierMetadata(
        name: "pureProxy10", moduleUrl: _appViewUtilsModuleUrl)
  ];
  // Runtime is initialized by output interpreter. Compiler executes in VM and
  // can't import dart:html to initialize here.
  static var HTML_COMMENT_NODE =
      CompileIdentifierMetadata(name: "Comment", moduleUrl: "dart:html");
  static var HTML_TEXT_NODE =
      CompileIdentifierMetadata(name: "Text", moduleUrl: "dart:html");
  static var HTML_DOCUMENT =
      CompileIdentifierMetadata(name: "document", moduleUrl: "dart:html");
  static final HTML_DOCUMENT_FRAGMENT = CompileIdentifierMetadata(
      name: 'DocumentFragment', moduleUrl: 'dart:html');
  static final HTML_ELEMENT =
      CompileIdentifierMetadata(name: "Element", moduleUrl: "dart:html");
  static final ElementToken = identifierToken(HTML_ELEMENT);
  static final HTML_HTML_ELEMENT =
      CompileIdentifierMetadata(name: "HtmlElement", moduleUrl: "dart:html");
  static final HtmlElementToken = identifierToken(HTML_HTML_ELEMENT);
  static final SVG_SVG_ELEMENT =
      CompileIdentifierMetadata(name: "SvgSvgElement", moduleUrl: "dart:svg");
  static final SVG_ELEMENT =
      CompileIdentifierMetadata(name: "SvgElement", moduleUrl: "dart:svg");
  static final HTML_ANCHOR_ELEMENT =
      CompileIdentifierMetadata(name: "AnchorElement", moduleUrl: "dart:html");
  static final HTML_DIV_ELEMENT =
      CompileIdentifierMetadata(name: "DivElement", moduleUrl: "dart:html");
  static final HTML_AREA_ELEMENT =
      CompileIdentifierMetadata(name: "AreaElement", moduleUrl: "dart:html");
  static final HTML_AUDIO_ELEMENT =
      CompileIdentifierMetadata(name: "AudioElement", moduleUrl: "dart:html");
  static final HTML_BUTTON_ELEMENT =
      CompileIdentifierMetadata(name: "ButtonElement", moduleUrl: "dart:html");
  static final HTML_CANVAS_ELEMENT =
      CompileIdentifierMetadata(name: "CanvasElement", moduleUrl: "dart:html");
  static final HTML_FORM_ELEMENT =
      CompileIdentifierMetadata(name: "FormElement", moduleUrl: "dart:html");
  static final HTML_IFRAME_ELEMENT =
      CompileIdentifierMetadata(name: "IFrameElement", moduleUrl: "dart:html");
  static final HTML_IMAGE_ELEMENT =
      CompileIdentifierMetadata(name: "ImageElement", moduleUrl: "dart:html");
  static final HTML_INPUT_ELEMENT =
      CompileIdentifierMetadata(name: "InputElement", moduleUrl: "dart:html");
  static final HTML_TEXTAREA_ELEMENT = CompileIdentifierMetadata(
      name: "TextAreaElement", moduleUrl: "dart:html");
  static final HTML_MEDIA_ELEMENT =
      CompileIdentifierMetadata(name: "MediaElement", moduleUrl: "dart:html");
  static final HTML_MENU_ELEMENT =
      CompileIdentifierMetadata(name: "MenuElement", moduleUrl: "dart:html");
  static final HTML_NODE_TREE_SANITIZER = CompileIdentifierMetadata(
      name: 'NodeTreeSanitizer', moduleUrl: 'dart:html');
  static final HTML_OPTION_ELEMENT =
      CompileIdentifierMetadata(name: "OptionElement", moduleUrl: "dart:html");
  static final HTML_OLIST_ELEMENT =
      CompileIdentifierMetadata(name: "OListElement", moduleUrl: "dart:html");
  static final HTML_SELECT_ELEMENT =
      CompileIdentifierMetadata(name: "SelectElement", moduleUrl: "dart:html");
  static final HTML_TABLE_ELEMENT =
      CompileIdentifierMetadata(name: "TableElement", moduleUrl: "dart:html");
  static final HTML_TABLE_ROW_ELEMENT = CompileIdentifierMetadata(
      name: "TableRowElement", moduleUrl: "dart:html");
  static final HTML_TABLE_COL_ELEMENT = CompileIdentifierMetadata(
      name: "TableColElement", moduleUrl: "dart:html");
  static final HTML_ULIST_ELEMENT =
      CompileIdentifierMetadata(name: "UListElement", moduleUrl: "dart:html");
  static final HTML_EVENT =
      CompileIdentifierMetadata(name: "Event", moduleUrl: "dart:html");
  static final HTML_NODE =
      CompileIdentifierMetadata(name: "Node", moduleUrl: "dart:html");

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
