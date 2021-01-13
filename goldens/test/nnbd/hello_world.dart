import 'package:angular/angular.dart';

import 'hello_world.template.dart' as ng;

void main() {
  runApp(ng.createHelloWorldComponentFactory());
}

@Component(
  selector: 'hello-world',
  template: 'Hello World',
)
class HelloWorldComponent {}
