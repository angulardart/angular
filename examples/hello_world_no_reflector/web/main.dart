import 'package:angular/angular.dart';

import 'main.template.dart' as ng_generated;

void main() {
  runApp(ng_generated.HelloWorldComponentNgFactory);
}

@Component(
  selector: 'hello-world',
  template: 'Hello World',
)
class HelloWorldComponent {}
