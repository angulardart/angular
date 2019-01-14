/// This library is considered separate from rest of `runtime.dart`, as it
/// imports `dart:html` and `runtime.dart` is currently used on libraries
/// that expect to only run on the command-line VM.
import 'dart:html';

import 'package:meta/dart2js.dart' as dart2js;

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
