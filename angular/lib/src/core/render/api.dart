import 'package:angular/src/core/di.dart' show Injector;
import 'package:angular/src/core/metadata/view.dart' show ViewEncapsulation;
import 'package:angular/src/runtime.dart';

/// Styles host that adds encapsulated styles to global style sheet for use
/// by [RenderComponentType].
abstract class SharedStylesHost {
  /// Adds [styles] to this style host.
  ///
  /// In dev mode the first style will be a identifier that may be used to
  /// attribute the [styles] to their component of origin.
  void addStyles(List<String> styles);
}

/// Application level shared style host to shim styles for components.
///
/// Initialized by RootRenderer.
SharedStylesHost sharedStylesHost;

/// This matches the component ID placeholder in encapsulating CSS classes.
final _componentIdPlaceholder = RegExp(r'%ID%');

/// Component prototype and runtime style information that are shared
/// across all instances of a component type.
class RenderComponentType {
  // Unique id for the component type of the form appId-compTypeId.
  final String id;
  // Url of component template used for debug builds.
  final String templateUrl;
  final ViewEncapsulation encapsulation;
  List<dynamic /* String | List < dynamic > */ > templateStyles;

  /// The prefix for CSS classes that style component host elements.
  static const _hostClassPrefix = '_nghost-';

  /// The prefix for CSS classes that encapsulate styles within component views.
  static const _viewClassPrefix = '_ngcontent-';

  // View attribute value assigned to elements in template or null if no
  // assignment is required.
  String _viewAttr;

  // Host attribute name of elements in the template for this component type.
  String _hostAttr;

  bool stylesShimmed = false;

  RenderComponentType(
      this.id, this.templateUrl, this.encapsulation, this.templateStyles);

  void shimStyles(SharedStylesHost stylesHost) {
    final styles = <String>[];
    if (isDevMode) {
      // In dev mode, pass the `templateUrl` as the first style. This is used by
      // the `SharedStyleHost` to attribute the resulting <style> tag to the
      // component from which it originates.
      styles.add(templateUrl);
    }
    _flattenStyles(id, templateStyles, styles);
    stylesHost.addStyles(styles);
    if (encapsulation == ViewEncapsulation.Emulated) {
      _hostAttr = '$_hostClassPrefix$id';
      _viewAttr = '$_viewClassPrefix$id';
    }
  }

  String get contentAttr => _viewAttr;

  String get hostAttr => _hostAttr;

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
        var styleString = unsafeCast<String>(style);
        styleString = styleString.replaceAll(_componentIdPlaceholder, compId);
        target.add(styleString);
      }
    }
    return target;
  }
}

abstract class RenderDebugInfo {
  Injector get injector;

  dynamic get component;

  List<dynamic> get providerTokens;

  Map<String, dynamic> get locals;

  String get source;
}
