import 'package:angular/angular.dart';

@Component(
  selector: 'CheckOnce',
  template: '<div>CheckOnce</div>',
  changeDetection: ChangeDetectionStrategy.CheckOnce,
)
class CheckOnceComponent {
  @HostBinding('id')
  String id;
}

@Component(
  selector: 'Checked',
  template: '<div>Checked</div>',
  changeDetection: ChangeDetectionStrategy.Checked,
)
class CheckedComponent {}

@Component(
  selector: 'CheckAlways',
  template: '<div>CheckAlways</div>',
  changeDetection: ChangeDetectionStrategy.CheckAlways,
)
class CheckAlwaysComponent {}

@Component(
  selector: 'Detached',
  template: '<div>Detached</div>',
  changeDetection: ChangeDetectionStrategy.Detached,
)
class DetachedComponent {}

@Component(
  selector: 'uses-cd-on-push',
  template: '<cd-on-push [name]="name"></cd-on-push>',
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
  changeDetection: ChangeDetectionStrategy.Stateful,
)
class StatefulComponent extends ComponentState {}

@Component(
  selector: 'Default',
  template: '<div>Default</div>',
  changeDetection: ChangeDetectionStrategy.Default,
)
class DefaultComponent {}
