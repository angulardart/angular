import 'package:angular/angular.dart';

@Component(
  selector: 'CheckOnce',
  template: '<div>CheckOnce</div>',
  host: const {'[id]': 'id'},
  changeDetection: ChangeDetectionStrategy.CheckOnce,
  // TODO(b/65383776): Change preserveWhitespace to false to improve codesize.
  preserveWhitespace: true,
)
class CheckOnceComponent {
  String id;
}

@Component(
  selector: 'Checked',
  template: '<div>Checked</div>',
  changeDetection: ChangeDetectionStrategy.Checked,
  // TODO(b/65383776): Change preserveWhitespace to false to improve codesize.
  preserveWhitespace: true,
)
class CheckedComponent {}

@Component(
  selector: 'CheckAlways',
  template: '<div>CheckAlways</div>',
  changeDetection: ChangeDetectionStrategy.CheckAlways,
  // TODO(b/65383776): Change preserveWhitespace to false to improve codesize.
  preserveWhitespace: true,
)
class CheckAlwaysComponent {}

@Component(
  selector: 'Detached',
  template: '<div>Detached</div>',
  changeDetection: ChangeDetectionStrategy.Detached,
  // TODO(b/65383776): Change preserveWhitespace to false to improve codesize.
  preserveWhitespace: true,
)
class DetachedComponent {}

@Component(
  selector: 'OnPush',
  template: '<div>OnPush</div>',
  changeDetection: ChangeDetectionStrategy.OnPush,
  // TODO(b/65383776): Change preserveWhitespace to false to improve codesize.
  preserveWhitespace: true,
)
class OnPushComponent {}

@Component(
  selector: 'Stateful',
  template: '<div>Stateful</div>',
  changeDetection: ChangeDetectionStrategy.Stateful,
  // TODO(b/65383776): Change preserveWhitespace to false to improve codesize.
  preserveWhitespace: true,
)
class StatefulComponent extends ComponentState {}

@Component(
  selector: 'Default',
  template: '<div>Default</div>',
  changeDetection: ChangeDetectionStrategy.Default,
  // TODO(b/65383776): Change preserveWhitespace to false to improve codesize.
  preserveWhitespace: true,
)
class DefaultComponent {}
