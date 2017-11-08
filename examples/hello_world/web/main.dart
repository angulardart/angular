import 'package:angular/angular.dart';

import 'main.template.dart' as ng_generated;

void main() {
  bootstrapStatic(HelloWorldComponent, [], ng_generated.initReflector);
}

@Component(
  selector: 'hello-world',
  template: 'Hello World',
)
class HelloWorldComponent {}
