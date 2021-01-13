import 'dart:html';

import 'package:meta/dart2js.dart' as dart2js;
import 'package:angular/src/runtime/check_binding.dart';

import 'interpolate.dart';

/// Wraps an HTML [Text] node, implementing change detection to make updating
/// the node's text property very fast.
/// This class is used in place of code-generated change detection in
/// Angular's .template.dart files, giving two benefits:
///    - avoids code duplication
///    - creates a hot function which JS engines (e.g. V8) can optimize.
class TextBinding {
  Object? _currentValue = '';
  final element = Text('');

  // This is a size optimization. dart2js will hoist the element field
  // initializer to a TextBinding constructor parameter, duplicating that
  // code in generated .template.dart files. Annotating an empty constructor
  // as noInline avoids that cost.
  @dart2js.noInline
  TextBinding();

  /// Update the [Text] node if [newValue] differs from the previous value.
  void updateText(String newValue) {
    if (checkBinding(_currentValue, newValue)) {
      element.text = newValue;
      _currentValue = newValue;
    }
  }

  /// Updates the [Text] node if [newValue]'s type is bool, num, int, or double
  /// and differs from the previous value.
  void updateTextWithPrimitive(Object? newValue) {
    if (checkBinding(_currentValue, newValue)) {
      element.text = interpolate0(newValue);
      _currentValue = newValue;
    }
  }
}
