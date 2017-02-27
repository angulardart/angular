import 'dart:async';
import 'dart:html';

import 'package:angular2/src/core/linker/element_ref.dart' show ElementRef;

class Rectangle {
  var left;
  var right;
  var top;
  var bottom;
  var height;
  var width;
  Rectangle(left, top, width, height) {
    this.left = left;
    this.right = left + width;
    this.top = top;
    this.bottom = top + height;
    this.height = height;
    this.width = width;
  }
}

class Ruler {
  Future<Rectangle> measure(ElementRef el) {
    Element elm = el.nativeElement;
    var clientRect = elm.getBoundingClientRect();
    // even if getBoundingClientRect is synchronous we use async API in
    // preparation for further changes
    return new Future.value(clientRect);
  }
}
