import 'package:angular/angular.dart';

@Directive(selector: 'directive')
class TestDirective {}

@Directive(selector: 'test-directive-with-inputs')
class TestDirectiveWithInputs {
  @Input()
  String input1;

  @Input()
  String input2;
}
