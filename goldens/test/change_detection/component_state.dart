@JS()
library golden;

import 'package:js/js.dart';
import 'package:angular/angular.dart';

import 'component_state.template.dart' as ng;

/// Avoids Dart2JS thinking something is constant/unchanging.
@JS()
external T deopt<T>([Object any]);

void main() {
  runApp(ng.createGoldenComponentFactory());
}

@Component(
  selector: 'golden',
  directives: [
    UsesComponentState,
    UsesComponentStateWithDoCheck,
  ],
  template: r'''
    <uses-component-state [name]="name"></uses-component-state>
    <uses-component-state-with-docheck [name]="name"></uses-component-state-with-docheck>
  ''',
)
class GoldenComponent {
  String name = deopt();
}

@Component(
  selector: 'uses-component-state',
  template: r'''
    Name: {{name}}
  ''',
)
class UsesComponentState extends ComponentState {
  @Input()
  String name;

  UsesComponentState() {
    deopt((String name) {
      setState(() {
        this.name = name;
      });
    });
  }
}

@Component(
  selector: 'uses-component-state-with-docheck',
  template: 'Name: {{name}}',
)
class UsesComponentStateWithDoCheck extends ComponentState implements DoCheck {
  @Input()
  String name;

  @override
  void ngDoCheck() {}
}
