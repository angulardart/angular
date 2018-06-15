import 'dart:html';

import 'package:angular/src/core/render/api.dart';
import 'package:angular/src/runtime.dart';

/// Implementation of DomSharedStyleHost for DOM.
class DomSharedStylesHost implements SharedStylesHost {
  final HeadElement _rootHost;
  final _stylesSet = Set<String>.identity();

  DomSharedStylesHost(HtmlDocument doc) : _rootHost = doc.head;

  @override
  void addStyles(List<String> styles) {
    for (var i = isDevMode ? 1 : 0, l = styles.length; i < l; i++) {
      final style = styles[i];
      if (_stylesSet.add(style)) {
        final styleElement = StyleElement()..text = style;
        if (isDevMode) {
          styleElement.setAttribute('from', styles[0]);
        }
        _rootHost.append(styleElement);
      }
    }
  }
}
