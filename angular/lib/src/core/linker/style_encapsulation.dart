import 'dart:html';

import 'package:angular/src/core/linker/app_view_utils.dart';
import 'package:angular/src/runtime.dart';
import 'package:meta/dart2js.dart' as dart2js;

/// Stores `styles: [ ... ]`,  `styleUrls: [ ... ]` for a given `@Component`.
class ComponentStyles {
  /// Originating URL of the `@Component`; used in debug builds only.
  final String _componentUrl;

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
  final String contentPrefix;

  /// CSS prefix applied to a component's host element for style encapsulation.
  final String hostPrefix;

  ComponentStyles._(
    this._styles,
    this.contentPrefix,
    this.hostPrefix, [
    this._componentId,
    this._componentUrl,
  ]) {
    _appendStyles();
  }

  static int _nextUniqueId = 0;
  static const _hostClassPrefix = '_nghost-';
  static const _viewClassPrefix = '_ngcontent-';

  /// Creates a [ComponentStyles] that applies style encapsulation.
  @dart2js.noInline
  factory ComponentStyles.scoped(
    List<Object> styles, [
    String componentUrl,
  ]) {
    final componentId = '${appViewUtils.appId}-${_nextUniqueId++}';
    return ComponentStyles._(
      styles,
      '$_viewClassPrefix$componentId',
      '$_hostClassPrefix$componentId',
      componentId,
      componentUrl,
    );
  }

  /// Creates a [ComponentStyles] that directly appends [styles] to the DOM.
  @dart2js.noInline
  factory ComponentStyles.unscoped(
    List<Object> styles, [
    String componentUrl,
  ]) = _UnscopedComponentStyles;

  /// Whether style encapsulation is used by this instance.
  ///
  /// TODO: Remove this field, and instead move the shimming code from `AppView`
  /// into this class, using the polymorphism (and [appendStyles]) to make CSS
  /// class decisions and not `AppView`.
  bool get usesStyleEncapsulation => true;

  /// Writes styles from this instance to [document.head] as a `<style>` tag.
  @dart2js.noInline
  void _appendStyles() {
    final target = <String>[];
    if (isDevMode) {
      target.add('/* From: $_componentUrl*/');
    }
    final styles = _flattenStyles(_styles, target, _componentId).join('\n');
    document.head.append(StyleElement()..text = styles);
  }
}

class _UnscopedComponentStyles extends ComponentStyles {
  _UnscopedComponentStyles(
    List<Object> styles, [
    String componentUrl,
  ]) : super._(styles, '', '', '', componentUrl);

  @override
  bool get usesStyleEncapsulation => false;
}

/// Flattens and appends [styles] to [target], returning the mutated [target].
List<String> _flattenStyles(
  List<Object> styles,
  List<String> target,
  String componentIdOrNull,
) {
  if (styles == null || styles.isEmpty) {
    return target;
  }
  for (var i = 0, l = styles.length; i < l; i++) {
    final styleOrList = styles[i];
    if (styleOrList is List<Object>) {
      _flattenStyles(
        styleOrList,
        target,
        componentIdOrNull,
      );
    } else {
      final styleString = unsafeCast<String>(styleOrList);
      target.add(styleString.replaceAll(_idPlaceholder, componentIdOrNull));
    }
  }
  return target;
}

final _idPlaceholder = RegExp('%ID%');
