import 'package:angular/angular.dart';

// ignore: uri_has_not_been_generated
import 'package:angular/angular.template.dart' as ng_lib;
// ignore: uri_has_not_been_generated
import 'package:angular/security.template.dart' deferred as security_lib;
// ignore: uri_has_not_been_generated
import 'package:_goldens/component.template.dart' as component_lib;

// We just want to see if "initReflector" is setup properly.
@Component(
  selector: 'test',
  template: '',
)
class TestComponent {
  TestComponent() {
    ng_lib.initReflector();
    security_lib.loadLibrary();
    component_lib.initReflector();
  }
}
