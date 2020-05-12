import 'package:angular/angular.dart';

@Component(
  selector: 'preserve-whitespace',
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
  selector: 'preserve-whitespace',
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
