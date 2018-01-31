import 'package:angular/angular.dart';

@Component(
  selector: 'CheckOnce',
  template: '<div>CheckOnce</div>',
  host: const {'[id]': 'id'},
  changeDetection: ChangeDetectionStrategy.CheckOnce,
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class CheckOnceComponent {
  String id;
}

@Component(
  selector: 'Checked',
  template: '<div>Checked</div>',
  changeDetection: ChangeDetectionStrategy.Checked,
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class CheckedComponent {}

@Component(
  selector: 'CheckAlways',
  template: '<div>CheckAlways</div>',
  changeDetection: ChangeDetectionStrategy.CheckAlways,
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class CheckAlwaysComponent {}

@Component(
  selector: 'Detached',
  template: '<div>Detached</div>',
  changeDetection: ChangeDetectionStrategy.Detached,
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class DetachedComponent {}

@Component(
  selector: 'OnPush',
  template: '<div>OnPush</div>',
  changeDetection: ChangeDetectionStrategy.OnPush,
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class OnPushComponent {}

@Component(
  selector: 'Stateful',
  template: '<div>Stateful</div>',
  changeDetection: ChangeDetectionStrategy.Stateful,
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class StatefulComponent extends ComponentState {}

@Component(
  selector: 'Default',
  template: '<div>Default</div>',
  changeDetection: ChangeDetectionStrategy.Default,
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class DefaultComponent {}
