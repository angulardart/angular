import 'package:angular/angular.dart';

import 'main.template.dart' as ng;

void main() => runApp(ng.HelloWorldComponentNgFactory);

@Component(
  selector: 'hello-world',
  template: 'Hello World',
)
class HelloWorldComponent {}
