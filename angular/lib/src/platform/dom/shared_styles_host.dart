import 'dart:html';

import 'package:angular/src/core/render/api.dart';

/// Implementation of DomSharedStyleHost for DOM.
class DomSharedStylesHost implements SharedStylesHost {
  final List<String> _styles = <String>[];
  final _stylesSet = new Set<String>();
  // Native ShadowDOM hosts.
  List _nativeHosts;
  final HeadElement _rootHost;

  DomSharedStylesHost(HtmlDocument doc) : _rootHost = doc.head;

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
      _rootHost.append(createStyleElement(style));
    }
    if (_nativeHosts != null) {
      onStylesAdded(additions);
    }
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
    Node host = hostNode;
    _addStylesToHost(_styles, host);
    _nativeHosts ??= <Node>[];
    _nativeHosts.add(hostNode);
  }

  @override
  void removeHost(dynamic hostNode) {
    _nativeHosts.remove(hostNode);
  }

  void onStylesAdded(List<String> additions) {
    if (_nativeHosts == null) return;
    for (var hostNode in _nativeHosts) {
      _addStylesToHost(additions, hostNode);
    }
  }
}
