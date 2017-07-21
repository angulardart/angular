import 'package:angular/src/core/di.dart' show Injector;
import 'package:angular/src/core/metadata/view.dart' show ViewEncapsulation;

/// Styles host that adds encapsulated styles to global style sheet for use
/// by [RenderComponentType].
abstract class SharedStylesHost {
  void addStyles(List<String> styles);
  void addHost(dynamic hostNode);
  void removeHost(dynamic hostNode);
  List<String> getAllStyles();
  dynamic createStyleElement(String css);
}

/// Application level shared style host to shim styles for components.
///
/// Initialized by RootRenderer.
SharedStylesHost sharedStylesHost;

final RegExp COMPONENT_REGEX = new RegExp(r'%COMP%');

/// Component prototype and runtime style information that are shared
/// across all instances of a component type.
class RenderComponentType {
  // Unique id for the component type of the form appId-compTypeId.
  final String id;
  // Url of component template used for debug builds.
  final String templateUrl;
  final ViewEncapsulation encapsulation;
  List<dynamic /* String | List < dynamic > */ > templateStyles;

  static const COMPONENT_VARIABLE = '%COMP%';
  static const HOST_STYLE_PREFIX = '_nghost-';
  static const CONTENT_STYLE_PREFIX = '_ngcontent-';
  static const HOST_ATTR = '$HOST_STYLE_PREFIX$COMPONENT_VARIABLE';
  static const CONTENT_ATTR = '$CONTENT_STYLE_PREFIX$COMPONENT_VARIABLE';
  // Content attribute value assigned to elements in template or null if
  // no assignment is required.
  String _contentAttr;
  // Host attribute name of elements in the template for this component type.
  String _hostAttr;

  List<String> _styles;
  bool stylesShimmed = false;

  RenderComponentType(
      this.id, this.templateUrl, this.encapsulation, this.templateStyles);

  void shimStyles(SharedStylesHost stylesHost) {
    _styles = _flattenStyles(id, templateStyles, []);
    stylesHost.addStyles(this._styles);
    if (encapsulation == ViewEncapsulation.Emulated) {
      _contentAttr = _shimContentAttribute(id);
      _hostAttr = _shimHostAttribute(id);
    }
  }

  String get contentAttr => _contentAttr;

  String get hostAttr => _hostAttr;

  List<String> get styles => _styles;

  String _shimContentAttribute(String componentShortId) =>
      CONTENT_ATTR.replaceAll(COMPONENT_REGEX, componentShortId);

  String _shimHostAttribute(String componentShortId) =>
      HOST_ATTR.replaceAll(COMPONENT_REGEX, componentShortId);

  List<String> _flattenStyles(
      String compId,
      List<dynamic /* dynamic | List < dynamic > */ > styles,
      List<String> target) {
    if (styles == null) return target;
    int styleCount = styles.length;
    for (var i = 0; i < styleCount; i++) {
      var style = styles[i];
      if (style is List) {
        _flattenStyles(compId, style, target);
      } else {
        style = style.replaceAll(COMPONENT_REGEX, compId);
        target.add(style);
      }
    }
    return target;
  }
}

abstract class RenderDebugInfo {
  Injector get injector;

  dynamic get component;

  List<dynamic> get providerTokens;

  Map<String, String> get locals;

  String get source;
}
