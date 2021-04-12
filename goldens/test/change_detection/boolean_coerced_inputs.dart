@JS()
library golden;

import 'package:js/js.dart';
import 'package:angular/angular.dart';

import 'boolean_coerced_inputs.template.dart' as ng;

/// Avoids Dart2JS thinking something is constant/unchanging.
@JS()
external T deopt<T>([Object? any]);

void main() {
  runApp(ng.createGoldenComponentFactory());
}

@Component(
  selector: 'golden',
  directives: [
    FancyButtonComponent,
  ],
  template: r'''
    <!-- Implicitly true -->
    <fancy-button raised></fancy-button>
    <fancy-button [raised]></fancy-button>

    <!-- Explicitly true or false -->
    <fancy-button [raised]="value"></fancy-button>
  ''',
)
class GoldenComponent {
  bool value = deopt();
}

@Component(
  selector: 'fancy-button',
  template: '',
)
class FancyButtonComponent {
  @Input()
  set raised(bool raised) => deopt(raised);
}
