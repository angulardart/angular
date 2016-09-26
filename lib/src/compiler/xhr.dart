// TODO: vsavkin rename it into TemplateLoader

import "dart:async";

/// An interface for retrieving documents by URL that the compiler uses
/// to load templates.
class XHR {
  Future<String> get(String url) {
    return null;
  }
}
