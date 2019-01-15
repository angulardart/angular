/// This library is considered separate from rest of `runtime.dart`, as it
/// imports `dart:html` and `runtime.dart` is currently used on libraries
/// that expect to only run on the command-line VM.
library angular.src.runtime.dom_helpers;

import 'dart:html';

import 'package:js/js_util.dart' as js;
import 'package:meta/dart2js.dart' as dart2js;

// Adds additional (missing) methods to `dart:html`'s [Element].
//
// TODO(https://github.com/dart-lang/sdk/issues/35655): Remove.

/// https://developer.mozilla.org/en-US/docs/Web/API/Element/removeAttribute
void _removeAttribute(Element e, String attribute) {
  js.callMethod(e, 'removeAttribute', [attribute]);
}

/// https://developer.mozilla.org/en-US/docs/Web/API/Element/removeAttributeNS
void _removeAttributeNS(Element e, String namespace, String attribute) {
  js.callMethod(e, 'removeAttributeNS', [attribute]);
}

/// Set to `true` when Angular modified the DOM.
///
/// May be used in order to optimize polling techniques that attempt to only
/// process events after a significant change detection cycle (i.e. one that
/// modified the DOM versus a no-op).
///
/// **NOTE**: What sets this to `true` (versus ignores it entirely) is currently
/// not consistent (it skips some methods that knowingly update the DOM). See
/// b/122842549.
var domRootRendererIsDirty = false;

/// Either adds or removes [className] to [element] based on [isAdd].
///
/// For example, the following template binding:
/// ```html
/// <div [class.warning]="isWarning">...</div>
/// ```
///
/// ... would emit:
/// ```dart
/// updateClassBinding(_divElement, 'warning', isWarning);
/// ```
///
/// For [element]s not guaranteed to be HTML, see [updateClassBindingNonHtml].
@dart2js.noInline
void updateClassBinding(HtmlElement element, String className, bool isAdd) {
  if (isAdd) {
    element.classes.add(className);
  } else {
    element.classes.remove(className);
  }
}

/// Similar to [updateClassBinding], for an [element] not guaranteed to be HTML.
///
/// For example, using [Element.tag] to create a custom element will not be
/// recognized as a built-in HTML element, or for SVG elements created by the
/// template.
///
/// Dart2JS emits slightly more optimized cost in [updateClassBinding].
@dart2js.noInline
void updateClassBindingNonHtml(Element element, String className, bool isAdd) {
  if (isAdd) {
    element.classes.add(className);
  } else {
    element.classes.remove(className);
  }
}

/// Updates [attribute] on [element] to reflect [value].
///
/// If [value] is `null`, this implicitly _removes_ [attribute] from [element].
@dart2js.noInline
void updateAttribute(
  Element element,
  String attribute,
  String value,
) {
  if (value == null) {
    _removeAttribute(element, attribute);
  } else {
    setAttribute(element, attribute, value);
  }
  domRootRendererIsDirty = true;
}

/// Similar to [updateAttribute], but supports name-spaced attributes.
@dart2js.noInline
void updateAttributeNS(
  Element element,
  String namespace,
  String attribute,
  String value,
) {
  if (value == null) {
    _removeAttributeNS(element, namespace, attribute);
  } else {
    element.setAttributeNS(namespace, attribute, value);
  }
  domRootRendererIsDirty = true;
}

/// Similar to [updateAttribute], but strictly for setting the initial [value].
///
/// This is meant as a slight optimization when initially building elements
/// from the template, as it does not check to see if [value] is `null` (and
/// the attribute should be removed) nor does it set [domRootRendererIsDirty].
@dart2js.noInline
void setAttribute(
  Element element,
  String attribute, [
  String value = '',
]) {
  element.setAttribute(attribute, value);
}
