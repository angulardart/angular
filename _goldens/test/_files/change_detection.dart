import 'package:angular/angular.dart';

@Component(
  selector: 'CheckOnce',
  template: '<div>CheckOnce</div>',
  host: const {'[id]': 'id'},
  changeDetection: ChangeDetectionStrategy.CheckOnce,
)
class CheckOnceComponent {
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
  selector: 'OnPush',
  template: '<div>OnPush</div>',
  changeDetection: ChangeDetectionStrategy.OnPush,
)
class OnPushComponent {}

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
