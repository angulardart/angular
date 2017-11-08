import 'package:angular/angular.dart';
import 'package:angular/experimental.dart';

import 'main.template.dart' as ng_generated;

void main() {
  bootstrapFactory(ng_generated.HelloWorldComponentNgFactory);
}

@Component(
  selector: 'hello-world',
  template: 'Hello World',
)
class HelloWorldComponent {}
