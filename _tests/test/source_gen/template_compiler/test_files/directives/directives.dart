import 'package:angular/angular.dart';

@Directive(selector: 'directive')
class TestDirective {}

@Directive(selector: 'test-directive-with-inputs', inputs: const ['input3'])
class TestDirectiveWithInputs {
  @Input()
  String input1;

  @Input()
  String input2;

  // Annotated via class element.
  String input3;
}
