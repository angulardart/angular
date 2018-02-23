import 'dart:collection' as collection_lib;
import 'package:angular/angular.dart';

@Directive(
  selector: 'directive',
)
class TestDirective {}

@Directive(
  selector: 'test-directive-with-inputs',
)
class TestDirectiveWithInputs {
  @Input()
  String input1;

  @Input()
  set input2(String input2) {}

  @Input()
  collection_lib.HashSet<DateTime> input3;

  @Input()
  set input4(collection_lib.HashMap<String, Duration> input5) {}
}
