import 'package:angular/angular.dart';

@Component(
  selector: 'uses-cd-on-push',
  template: '<cd-on-push [name]="name"></cd-on-push>',
  directives: [OnPushComponent],
)
class UsesOnPushComponent {
  String name;
}

@Component(
  selector: 'cd-on-push',
  template: '<cd-on-push-child [name]="name"></cd-on-push-child>',
  directives: [OnPushChildComponent],
  changeDetection: ChangeDetectionStrategy.OnPush,
)
class OnPushComponent {
  @Input()
  String name;
}

@Component(
  selector: 'cd-on-push-child',
  template: '<div>OnPushChild: {{name}}</div>',
  changeDetection: ChangeDetectionStrategy.OnPush,
)
class OnPushChildComponent {
  @Input()
  String name;
}

@Component(
  selector: 'Stateful',
  template: '<div>Stateful</div>',
)
class StatefulComponent extends ComponentState {}

@Component(
  selector: 'Default',
  template: '<div>Default</div>',
)
class DefaultComponent {}
