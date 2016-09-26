import "package:angular2/src/platform/dom/dom_adapter.dart" show DOM;

/// A service that can be used to get and set the title of a current HTML document.
///
/// Since an Angular 2 application can't be bootstrapped on the entire HTML document (`<html>` tag)
/// it is not possible to bind to the `text` property of the `HTMLTitleElement` elements
/// (representing the `<title>` tag). Instead, this service can be used to set and get the current
/// title value.
class Title {
  /// Get the title of the current HTML document.
  String getTitle() {
    return DOM.getTitle();
  }

  /// Set the title of the current HTML document.
  void setTitle(String newTitle) {
    DOM.setTitle(newTitle);
  }
}
