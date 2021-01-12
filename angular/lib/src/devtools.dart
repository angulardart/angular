@JS()
library angular.src.devtools;

import 'dart:html' as html;

import 'package:js/js.dart';

import 'devtools/component_inspector.dart';
import 'utilities.dart';

export 'devtools/component_inspector.dart';

/// Whether developer tools are enabled.
///
/// This is always false in release mode.
bool get isDevToolsEnabled => isDevMode && _isDevToolsEnabled;
bool _isDevToolsEnabled = false;

/// Enables developer tools if in development mode.
///
/// Calling this method in release mode has no effect.
void enableDevTools() {
  if (isDevMode) {
    _isDevToolsEnabled = true;
    _getComponentElement = allowInterop(
      ComponentInspector.instance.getComponentElement,
    );
  }
}

/// Specifies a function to look up an element by component ID in JavaScript.
@JS('getAngularComponentElement')
external set _getComponentElement(
  html.HtmlElement Function(int) implementation,
);
