import 'package:angular/angular.dart';

@Component(
  selector: 'test-bar', template: '<div>Bar</div>',
  // TODO(b/65383776): Change preserveWhitespace to false to improve codesize.
  preserveWhitespace: true,
)
class TestSubComponent {}
