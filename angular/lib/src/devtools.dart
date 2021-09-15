@JS()
library angular.src.devtools;

import 'dart:html' as html;

import 'package:js/js.dart';

import 'devtools/inspector.dart';
import 'utilities.dart';

export 'devtools/inspector.dart';
export 'devtools/model.dart';

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
      Inspector.instance.getComponentElement,
    );
    _getComponentIdForNode = allowInterop(
      Inspector.instance.getComponentIdForNode,
    );
  }
}

/// Registers [element] as an additional location to search for components.
///
/// This method should be used to register elements that are not contained by
/// the app's root component.
void registerContentRoot(html.Element element) {
  if (isDevToolsEnabled) {
    Inspector.instance.registerContentRoot(element);
  }
}

/// Specifies a function to look up an element by component ID in JavaScript.
@JS('getAngularComponentElement')
external set _getComponentElement(
  html.HtmlElement Function(int) implementation,
);

@JS('getAngularComponentIdForNode')
external set _getComponentIdForNode(
  void Function(html.Node, String) implementation,
);
