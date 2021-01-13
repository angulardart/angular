@JS()
library golden;

import 'package:js/js.dart';
import 'package:angular/angular.dart';

import 'whitespace.template.dart' as ng;

void main() {
  runApp(ng.createGoldenComponentFactory());
}

@Component(
  selector: 'golden',
  directives: [
    PreserveWhitespace,
    MinifyWhitespace,
  ],
  template: '''
    <preserve-whitespace-true></preserve-whitespace-true>
    <preserve-whitespace-false></preserve-whitespace-false>
  ''',
)
class GoldenComponent {}

@Component(
  selector: 'preserve-whitespace-true',
  template: r'''
    <div>
      Welcome...
      To...
      <strong>Jurassic...</strong>
      Park!
    </div>
    <div @i18n="i18n description">
      Default i18n text
    </div>
  ''',
  preserveWhitespace: true,
)
class PreserveWhitespace {}

@Component(
  selector: 'preserve-whitespace-false',
  template: r'''
    <div>
      Welcome...
      To...
      <strong>Jurassic...</strong>
      Park!
    </div>
    <div @i18n="i18n description">
      Default i18n text
    </div>
  ''',
)
class MinifyWhitespace {}
