@JS()
library golden;

import 'package:js/js.dart';
import 'package:angular/angular.dart';

import 'on_push.template.dart' as ng;

/// Avoids Dart2JS thinking something is constant/unchanging.
@JS()
external T deopt<T>([Object? any]);

void main() {
  runApp(ng.createGoldenComponentFactory());
}

@Component(
  selector: 'golden',
  directives: [
    Child,
    ChildWithDoCheck,
  ],
  template: r'''
    <child [name]="name"></child>
    <child-with-do-check [name]="name"></child-with-do-check>
  ''',
  changeDetection: ChangeDetectionStrategy.OnPush,
)
class GoldenComponent {
  String name = deopt();
}

@Component(
  selector: 'child',
  template: 'Name: {{name}}',
  changeDetection: ChangeDetectionStrategy.OnPush,
)
class Child {
  @Input()
  String? name;
}

@Component(
  selector: 'child-with-do-check',
  template: 'Name: {{name}}',
  changeDetection: ChangeDetectionStrategy.OnPush,
)
class ChildWithDoCheck implements DoCheck {
  @Input()
  String? name;

  @override
  void ngDoCheck() {}
}
