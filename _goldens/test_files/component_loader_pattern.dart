import 'package:angular/angular.dart';

// ignore: uri_has_not_been_generated
import 'package:angular/di.template.dart' as di_lib;
// ignore: uri_has_not_been_generated
import 'package:angular/security.template.dart' deferred as security_lib;
// ignore: uri_has_not_been_generated
import 'example_of_file_that_is_not_generated_yet.template.dart' as example_lib;

// We just want to see if "initReflector" is setup properly.
@Component(
  selector: 'test',
  template: '',
  // TODO(b/65383776): Change preserveWhitespace to false to improve codesize.
  preserveWhitespace: true,
)
class TestComponent {
  TestComponent() {
    di_lib.initReflector();
    security_lib.loadLibrary();
    example_lib.initReflector();
  }
}
