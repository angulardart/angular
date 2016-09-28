import 'dart:html';

import 'package:angular2/src/core/render/api.dart';

/// Implementation of DomSharedStyleHost for DOM.
class DomSharedStylesHost implements SharedStylesHost {
  List<String> _styles = [];
  var _stylesSet = new Set<String>();
  var _hostNodes = new Set();

  DomSharedStylesHost(dynamic doc) {
    _hostNodes.add(doc.head);
  }

  @override
  dynamic createStyleElement(String css) {
    StyleElement el = document.createElement('STYLE');
    el.text = css;
    return el;
  }

  @override
  void addStyles(List<String> styles) {
    int styleCount = styles.length;
    var additions = <String>[];
    for (int i = 0; i < styleCount; i++) {
      String style = styles[i];
      if (_stylesSet.contains(style)) continue;
      _stylesSet.add(style);
      _styles.add(style);
      additions.add(style);
    }
    onStylesAdded(additions);
  }

  @override
  List<String> getAllStyles() {
    return _styles;
  }

  void _addStylesToHost(List<String> styles, dynamic host) {
    int styleCount = styles.length;
    for (var i = 0; i < styleCount; i++) {
      host.append(createStyleElement(styles[i]));
    }
  }

  @override
  void addHost(dynamic hostNode) {
    _addStylesToHost(_styles, hostNode);
    _hostNodes.add(hostNode);
  }

  @override
  void removeHost(dynamic hostNode) {
    _hostNodes.remove(hostNode);
  }

  void onStylesAdded(List<String> additions) {
    _hostNodes.forEach((hostNode) {
      _addStylesToHost(additions, hostNode);
    });
  }
}
