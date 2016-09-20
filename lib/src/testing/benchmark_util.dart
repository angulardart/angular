import "package:angular2/src/facade/browser.dart" show document, window;
import "package:angular2/src/facade/exceptions.dart" show BaseException;
import "package:angular2/src/platform/browser/browser_adapter.dart"
    show BrowserDomAdapter;

var DOM = new BrowserDomAdapter();
int getIntParameter(String name) {
  return int.parse(getStringParameter(name), radix: 10);
}

String getStringParameter(String name) {
  var els = DOM.querySelectorAll(document, '''input[name="${ name}"]''');
  var value;
  var el;
  for (var i = 0; i < els.length; i++) {
    el = els[i];
    var type = DOM.type(el);
    if ((type != "radio" && type != "checkbox") || DOM.getChecked(el)) {
      value = DOM.getValue(el);
      break;
    }
  }
  if (value == null) {
    throw new BaseException(
        '''Could not find and input field with name ${ name}''');
  }
  return value;
}

void bindAction(String selector, Function callback) {
  var el = DOM.querySelector(document, selector);
  DOM.on(el, "click", (_) {
    callback();
  });
}

void microBenchmark(name, iterationCount, callback) {
  var durationName = '''${ name}/${ iterationCount}''';
  window.console.time(durationName);
  callback();
  window.console.timeEnd(durationName);
}

void windowProfile(String name) {
  ((window.console as dynamic)).profile(name);
}

void windowProfileEnd(String name) {
  ((window.console as dynamic)).profileEnd(name);
}
