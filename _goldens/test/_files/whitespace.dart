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
  ''',
)
class MinifyWhitespace {}
