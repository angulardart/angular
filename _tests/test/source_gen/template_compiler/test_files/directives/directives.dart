import 'dart:collection' as collection_lib;
import 'package:angular/angular.dart';

@Directive(selector: 'directive')
class TestDirective {}

@Directive(selector: 'test-directive-with-inputs', inputs: const ['input3'])
class TestDirectiveWithInputs {
  @Input()
  String input1;

  @Input()
  set input2(String input2) {}

  // Annotated via class element.
  String input3;

  @Input()
  collection_lib.HashSet<DateTime> input4;

  @Input()
  set input5(collection_lib.HashMap<String, Duration> input5) {}
}
