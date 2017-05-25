import 'dart:html';

import "package:angular2/src/facade/exceptions.dart" show BaseException;

int getIntParameter(String name) {
  return int.parse(getStringParameter(name), radix: 10);
}

String getStringParameter(String name) {
  var els = document.querySelectorAll('input[name="$name"]');
  var value;
  InputElement el;
  for (var i = 0; i < els.length; i++) {
    el = els[i] as InputElement;
    var type = el.type;
    if ((type != "radio" && type != "checkbox") || el.checked) {
      value = el.value;
      break;
    }
  }
  if (value == null) {
    throw new BaseException('Could not find and input field with name $name');
  }
  return value;
}

void bindAction(String selector, Function callback) {
  var el = document.querySelector(selector);
  el.onClick.listen((MouseEvent e) {
    callback();
  });
}

void microBenchmark(name, iterationCount, callback) {
  var durationName = '$name/$iterationCount';
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
