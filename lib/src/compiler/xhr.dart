// This was never meant to be a user-visibile API.
@Deprecated('If you need this, import package:angular2/reflection.dart')
library angular2_deprecated_xhr;

import "dart:async";

/// An interface for retrieving documents by URL that the compiler uses
/// to load templates.
class XHR {
  Future<String> get(String url) {
    return null;
  }
}
