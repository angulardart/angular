import "compile_metadata.dart"
    show CompileIdentifierMetadata, CompileTokenMetadata;

const _angularLib = 'asset:angular/lib';

const _appViewUtilsModuleUrl =
    "$_angularLib/src/core/linker/app_view_utils.dart";
const _proxiesModuleUrl = '$_angularLib/src/runtime/proxies.dart';
const _cdModuleUrl =
    "$_angularLib/src/core/change_detection/change_detection.dart";
const _angularRootUrl = "package:angular/angular.dart";
const _ngIfUrl = "$_angularLib/src/common/directives/ng_if.dart";
const _ngForUrl = "$_angularLib/src/common/directives/ng_for.dart";
const _profileRuntimeModuleUrl = "$_angularLib/src/debug/profile_runtime.dart";
const _debugInjectorModuleUrl = '$_angularLib/src/di/errors.dart';

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

class Views {
  const Views._();

  static CompileIdentifierMetadata _of(String name, String file) {
    return CompileIdentifierMetadata(
      name: name,
      moduleUrl: '$_angularLib/src/core/linker/views/$file',
    );
  }

  static final componentView = _of('ComponentView', 'component_view.dart');
  static final embeddedView = _of('EmbeddedView', 'embedded_view.dart');
  static final hostView = _of('HostView', 'host_view.dart');
  static final renderView = _of('RenderView', 'render_view.dart');
  static final view = _of('View', 'view.dart');
}

class Interpolation {
  static const _moduleUrl = '$_angularLib/src/runtime/interpolate.dart';

  const Interpolation._();

  static CompileIdentifierMetadata _interpolate(int n) {
    return CompileIdentifierMetadata(
      name: 'interpolate$n',
      moduleUrl: _moduleUrl,
    );
  }

  static CompileIdentifierMetadata _interpolateString(int n) {
    return CompileIdentifierMetadata(
      name: 'interpolateString$n',
      moduleUrl: _moduleUrl,
    );
  }

  static final interpolate = List<CompileIdentifierMetadata>.generate(
    10,
    _interpolate,
  );

  static final interpolateString = List<CompileIdentifierMetadata>.generate(
    10,
    _interpolateString,
  );

  static final textBinding = CompileIdentifierMetadata(
    name: 'TextBinding',
    moduleUrl: '$_angularLib/src/runtime/text_binding.dart',
  );
}

class Runtime {
  static const _moduleUrl = '$_angularLib/src/runtime.dart';

  const Runtime._();

  static final checkBinding = CompileIdentifierMetadata(
    name: 'checkBinding',
    moduleUrl: _moduleUrl,
  );

  static final debugThrowIfChanged = CompileIdentifierMetadata(
    name: 'debugThrowIfChanged',
    moduleUrl: _moduleUrl,
  );

  static final isDevMode = CompileIdentifierMetadata(
    name: 'isDevMode',
    moduleUrl: _moduleUrl,
  );

  static final unsafeCast = CompileIdentifierMetadata(
    name: 'unsafeCast',
    moduleUrl: _moduleUrl,
  );
}

class Queries {
  static const _moduleUrl = '$_angularLib/src/runtime/queries.dart';

  const Queries._();

  static final flattenNodes = CompileIdentifierMetadata(
    name: 'flattenNodes',
    moduleUrl: _moduleUrl,
  );

  static final firstOrNull = CompileIdentifierMetadata(
    name: 'firstOrNull',
    moduleUrl: _moduleUrl,
  );
}

class Identifiers {
  static final appViewUtils = CompileIdentifierMetadata(
      name: "appViewUtils", moduleUrl: _appViewUtilsModuleUrl);
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
  static final ComponentRef = CompileIdentifierMetadata(
      name: "ComponentRef", moduleUrl: _angularRootUrl);
  static final TemplateRef = CompileIdentifierMetadata(
      name: "TemplateRef",
      moduleUrl: "asset:angular/lib/src/core/linker/template_ref.dart");
  static final TemplateRefToken = identifierToken(Identifiers.TemplateRef);
  static final Injector = CompileIdentifierMetadata(
      name: "Injector",
      moduleUrl: 'asset:angular/lib/src/di/injector/injector.dart');
  static final InjectorToken = identifierToken(Identifiers.Injector);
  static final ViewType = CompileIdentifierMetadata(
      name: "ViewType",
      moduleUrl: 'asset:angular/lib/src/core/linker/view_type.dart');
  static final ChangeDetectionStrategy = CompileIdentifierMetadata(
      name: "ChangeDetectionStrategy", moduleUrl: _cdModuleUrl);
  static final identical = CompileIdentifierMetadata(name: "identical");
  static final profileSetup = CompileIdentifierMetadata(
      name: "profileSetup", moduleUrl: _profileRuntimeModuleUrl);
  static final profileMarkStart = CompileIdentifierMetadata(
      name: "profileMarkStart", moduleUrl: _profileRuntimeModuleUrl);
  static final profileMarkEnd = CompileIdentifierMetadata(
      name: "profileMarkEnd", moduleUrl: _profileRuntimeModuleUrl);
  static final loadDeferred = CompileIdentifierMetadata(
      name: "loadDeferred", moduleUrl: _appViewUtilsModuleUrl);
  static final debugInjectorEnter = CompileIdentifierMetadata(
      name: "debugInjectorEnter", moduleUrl: _debugInjectorModuleUrl);
  static final debugInjectorLeave = CompileIdentifierMetadata(
      name: "debugInjectorLeave", moduleUrl: _debugInjectorModuleUrl);
  static final debugInjectorWrap = CompileIdentifierMetadata(
      name: "debugInjectorWrap", moduleUrl: _debugInjectorModuleUrl);

  static final createTrustedHtml = CompileIdentifierMetadata(
      name: 'createTrustedHtml', moduleUrl: _appViewUtilsModuleUrl);
  static final emptyListLiteral = CompileIdentifierMetadata(
      name: "emptyListLiteral", moduleUrl: _proxiesModuleUrl);
  static final pureProxies = [
    null,
    CompileIdentifierMetadata(name: "pureProxy1", moduleUrl: _proxiesModuleUrl),
    CompileIdentifierMetadata(name: "pureProxy2", moduleUrl: _proxiesModuleUrl),
    CompileIdentifierMetadata(name: "pureProxy3", moduleUrl: _proxiesModuleUrl),
    CompileIdentifierMetadata(name: "pureProxy4", moduleUrl: _proxiesModuleUrl),
    CompileIdentifierMetadata(name: "pureProxy5", moduleUrl: _proxiesModuleUrl),
    CompileIdentifierMetadata(name: "pureProxy6", moduleUrl: _proxiesModuleUrl),
    CompileIdentifierMetadata(name: "pureProxy7", moduleUrl: _proxiesModuleUrl),
    CompileIdentifierMetadata(name: "pureProxy8", moduleUrl: _proxiesModuleUrl),
    CompileIdentifierMetadata(name: "pureProxy9", moduleUrl: _proxiesModuleUrl),
    CompileIdentifierMetadata(name: "pureProxy10", moduleUrl: _proxiesModuleUrl)
  ];

  static final NG_IF_DIRECTIVE =
      CompileIdentifierMetadata(name: "NgIf", moduleUrl: _ngIfUrl);
  static final NG_FOR_DIRECTIVE =
      CompileIdentifierMetadata(name: "NgFor", moduleUrl: _ngForUrl);

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
