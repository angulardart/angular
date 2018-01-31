import 'package:angular/angular.dart';

import 'main.template.dart' as ng_generated;

void main() {
  bootstrapStatic(HelloWorldComponent, [], ng_generated.initReflector);
}

@Component(
  selector: 'hello-world',
  template: 'Hello World',
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class HelloWorldComponent {}
