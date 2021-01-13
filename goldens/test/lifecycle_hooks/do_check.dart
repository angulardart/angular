@JS()
library golden;

import 'package:js/js.dart';
import 'package:angular/angular.dart';

import 'do_check.template.dart' as ng;

/// Avoids Dart2JS thinking something is constant/unchanging.
@JS()
external T deopt<T>([Object? any]);

void main() {
  runApp(ng.createGoldenComponentFactory());
}

@Component(
  selector: 'golden',
  directives: [UsesDoCheck],
  template: '<uses-do-check [a]="a" [b]="b" [c]="c"></uses-do-check>',
)
class GoldenComponent {
  late String a;
  late String b;
  late String c;

  GoldenComponent() {
    deopt(() {
      a = deopt('a');
      b = deopt('b');
      c = deopt('c');
    });
  }
}

@Component(
  selector: 'uses-do-check',
  template: '',
)
class UsesDoCheck implements DoCheck {
  @Input()
  String? a;

  @Input()
  String? b;

  @Input()
  String? c;

  @override
  void ngDoCheck() {
    deopt([a, b, c]);
  }
}
