import 'dart:html';

import 'package:meta/dart2js.dart' as dart2js;
import 'package:angular/src/core/linker/app_view_utils.dart';
import 'package:angular/src/runtime/dom_helpers.dart';
import 'package:angular/src/utilities.dart';

/// Clears all component styles from the DOM.
///
/// This should only be called in development mode, typically to reset `<style>`
/// tags in the DOM between DDC hot restarts or hermetic test cases.
void debugClearComponentStyles() {
  if (!isDevMode) {
    throw StateError(
      'This function should only be used in development mode.\n'
      '\n'
      'See "debugClearComponentStyles()" documentation for details.',
    );
  }
  ComponentStyles._debugClear();
}

/// Stores `styles: [ ... ]`,  `styleUrls: [ ... ]` for a given `@Component`.
class ComponentStyles {
  /// Callbacks to invoke when [_debugClear] is called.
  static List<void Function()>? _debugClearCallbacks;

  /// See [debugClearComponentStyles].
  static void _debugClear() {
    final debugClearCallbacks = _debugClearCallbacks;
    if (debugClearCallbacks != null) {
      for (final callback in debugClearCallbacks) {
        callback();
      }
      debugClearCallbacks.clear();
    }
  }

  /// Registers a [callback] to be called by [_debugClear].
  ///
  /// Used to remove all component `<style>` elements in the DOM and clear
  /// static component styles in generated views.
  static void debugOnClear(void Function() callback) {
    (_debugClearCallbacks ??= []).add(callback);
  }

  /// Originating URL of the `@Component`; used in debug builds only.
  final String? _componentUrl;

  /// A `List<String | List<String>>` of all styles for a given component.
  ///
  /// **NOTE**: It might seem compelling to try to simplify this to either a
  /// `List<String>` or a `String`. While in practice this _is_ possible, the
  /// current data structure exists in order to optimize for style re-use:
  ///
  /// ```
  /// @Component(
  ///   styleUrls: ['shared.css'],
  /// )
  /// class A {}
  ///
  /// @Component(
  ///   styleUrls: ['shared.css'],
  /// )
  /// class B {}
  /// ```
  ///
  /// ... both `A` and `B` will refer to a pre-processed `.dart` file on disk
  /// (`shared.css.dart` or `shared.css.shim.dart` for style encapsulation). If
  /// we ever choose to stop optimizing for this use case we can simplify this
  /// data structure.
  final List<Object> _styles;

  /// A generated unique ID for this component, used for encapsulation
  final String _componentId;

  /// CSS prefix applied to elements in a template for style encapsulation.
  final String _contentPrefix;

  /// CSS prefix applied to a component's host element for style encapsulation.
  final String _hostPrefix;

  ComponentStyles._(
    this._styles,
    this._componentUrl, [
    this._componentId = '',
    this._contentPrefix = '',
    this._hostPrefix = '',
  ]) {
    _appendStyles();
  }

  static int _nextUniqueId = 0;
  static const _hostClassPrefix = '_nghost-';
  static const _viewClassPrefix = '_ngcontent-';

  /// Creates a [ComponentStyles] that applies style encapsulation.
  @dart2js.noInline
  factory ComponentStyles.scoped(List<Object> styles, String? componentUrl) {
    final componentId = '${appViewUtils.appId}-${_nextUniqueId++}';
    return ComponentStyles._(
      styles,
      componentUrl,
      componentId,
      '$_viewClassPrefix$componentId',
      '$_hostClassPrefix$componentId',
    );
  }

  /// Creates a [ComponentStyles] that directly appends [styles] to the DOM.
  @dart2js.noInline
  factory ComponentStyles.unscoped(
    List<Object> styles,
    String? componentUrl,
  ) = _UnscopedComponentStyles;

  /// Adds a CSS shim class to [element].
  void addContentShimClass(Element element) {
    updateClassBindingNonHtml(element, _contentPrefix, true);
  }

  /// An optimized variant of [addShimClass] for [HtmlElement]s.
  void addContentShimClassHtmlElement(HtmlElement element) {
    updateClassBinding(element, _contentPrefix, true);
  }

  /// Adds a CSS shim class to [element].
  void addHostShimClass(Element element) {
    updateClassBindingNonHtml(element, _hostPrefix, true);
  }

  /// An optimized variant of [addHostShimClass] for [HtmlElement]s.
  void addHostShimClassHtmlElement(HtmlElement element) {
    updateClassBinding(element, _hostPrefix, true);
  }

  /// Applies the correct content shimming to [element] for [newClass].
  void updateChildClass(Element element, String newClass) {
    // NOTE: We do not use .className=, because that would fail for SvgElement.
    updateAttribute(element, 'class', '$newClass $_contentPrefix');
  }

  /// An optimized variant of [updateChildClass] for [HtmlElement]s.
  void updateChildClassHtmlElement(HtmlElement element, String newClass) {
    element.className = '$newClass $_contentPrefix';
  }

  /// Applies the correct host shimming to [element] for [newClass].
  void updateChildClassForHost(Element element, String newClass) {
    // NOTE: We do not use .className=, because that would fail for SvgElement.
    updateAttribute(element, 'class', '$newClass $_hostPrefix');
  }

  /// An optimized variant of [updateChildClassForHost] for [HtmlElement]s.
  void updateChildClassForHostHtmlElement(
    HtmlElement element,
    String newClass,
  ) {
    element.className = '$newClass $_hostPrefix';
  }

  /// Writes styles from this instance to [document.head] as a `<style>` tag.
  @dart2js.noInline
  void _appendStyles() {
    final target = <String>[];
    if (isDevMode) {
      target.add('/* From: $_componentUrl*/');
    }
    final styles = _flattenStyles(_styles, target, _componentId).join();
    final styleElement = StyleElement()..text = styles;
    if (isDevMode) {
      // Remove style element from the DOM on hot restart.
      debugOnClear(() {
        styleElement.remove();
      });
    }
    document.head!.append(styleElement);
  }
}

class _UnscopedComponentStyles extends ComponentStyles {
  _UnscopedComponentStyles(
    List<Object> styles,
    String? componentUrl,
  ) : super._(styles, componentUrl);

  @override
  void addContentShimClass(Element element) {
    // Intentionally left blank; unscoped syles do not apply shim classes.
  }

  @override
  void addContentShimClassHtmlElement(HtmlElement element) {
    // Intentionally left blank; unscoped syles do not apply shim classes.
  }

  @override
  void addHostShimClass(Element element) {
    // Intentionally left blank; unscoped syles do not apply shim classes.
  }

  @override
  void addHostShimClassHtmlElement(HtmlElement element) {
    // Intentionally left blank; unscoped syles do not apply shim classes.
  }

  @override
  void updateChildClass(Element element, String newClass) {
    // Straight applies the class without any prefixing.
    // NOTE: We do not use .className=, because that would fail for SvgElement.
    updateAttribute(element, 'class', newClass);
  }

  @override
  void updateChildClassHtmlElement(HtmlElement element, String newClass) {
    element.className = newClass;
  }

  @override
  void updateChildClassForHost(Element element, String newClass) {
    // Straight applies the class without any prefixing.
    // NOTE: We do not use .className=, because that would fail for SvgElement.
    updateAttribute(element, 'class', newClass);
  }

  @override
  void updateChildClassForHostHtmlElement(
    HtmlElement element,
    String newClass,
  ) {
    // Straight applies the class without any prefixing.
    element.className = newClass;
  }
}

/// Flattens and appends [styles] to [target], returning the mutated [target].
List<String> _flattenStyles(
  List<Object> styles,
  List<String> target,
  String componentId,
) {
  if (styles.isEmpty) {
    return target;
  }
  for (var i = 0, l = styles.length; i < l; i++) {
    final styleOrList = styles[i];
    if (styleOrList is List<Object>) {
      _flattenStyles(styleOrList, target, componentId);
    } else {
      final styleString = unsafeCast<String>(styleOrList);
      target.add(styleString.replaceAll(_idPlaceholder, componentId));
    }
  }
  return target;
}

final _idPlaceholder = RegExp('%ID%');
