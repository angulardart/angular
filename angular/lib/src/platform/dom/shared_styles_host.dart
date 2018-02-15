import 'dart:html';

import 'package:angular/src/core/render/api.dart';

/// Implementation of DomSharedStyleHost for DOM.
class DomSharedStylesHost implements SharedStylesHost {
  final HeadElement _rootHost;
  final _stylesSet = new Set<String>.identity();

  DomSharedStylesHost(HtmlDocument doc) : _rootHost = doc.head;

  @override
  void addStyles(List<String> styles) {
    for (var i = 0, l = styles.length; i < l; i++) {
      final style = styles[i];
      if (_stylesSet.add(style)) {
        _rootHost.append(new StyleElement()..text = style);
      }
    }
  }
}
