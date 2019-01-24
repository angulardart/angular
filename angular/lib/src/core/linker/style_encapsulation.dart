import 'dart:html';

import 'package:angular/src/runtime.dart';

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

  /// Tracks whether [appendStyles] has been used already on an element.
  final _isAppendedTo = Expando<bool>();

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
  ]);

  static int _nextUniqueId = 0;
  static const _hostClassPrefix = '_nghost-';
  static const _viewClassPrefix = '_ngcontent-';

  /// Creates a [ComponentStyles] that applies style encapsulation.
  factory ComponentStyles.scoped(
    List<Object> styles, [
    String componentUrl,
  ]) {
    final componentId = (_nextUniqueId++).toString();
    return ComponentStyles._(
      styles,
      '$_viewClassPrefix$componentId',
      '$_hostClassPrefix$componentId',
      componentId,
      componentUrl,
    );
  }

  /// Creates a [ComponentStyles] that directly appends [styles] to the DOM.
  factory ComponentStyles.unscoped(
    List<Object> styles, [
    String componentUrl,
  ]) {
    return ComponentStyles._(
      styles,
      '',
      '',
      '',
      componentUrl,
    );
  }

  /// Writes styles from this instance to [parent] as a `<style>` tag.
  void appendStyles(HtmlElement parent) {
    if (identical(_isAppendedTo[parent], true)) {
      return;
    }
    final target = <String>[];
    if (isDevMode) {
      target.add('/* From: $_componentUrl*/');
    }
    final styles = _flattenStyles(_styles, target, _componentId).join('\n');
    parent.append(StyleElement()..text = styles);
    _isAppendedTo[parent] = true;
  }
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
  // The inbound lists should always be JSArray, so for-in is fine to use.
  for (final styleOrList in styles) {
    if (styleOrList is List) {
      _flattenStyles(
        styleOrList,
        target,
        componentIdOrNull,
      );
    } else {
      final styleString = unsafeCast<String>(styleOrList);
      target.add(styleString.replaceAll('%ID%', componentIdOrNull));
    }
  }
  return target;
}
