// TODO: vsavkin rename it into TemplateLoader

/**
 * An interface for retrieving documents by URL that the compiler uses
 * to load templates.
 */
library angular2.src.compiler.xhr;

import "dart:async";

class XHR {
  Future<String> get(String url) {
    return null;
  }
}
