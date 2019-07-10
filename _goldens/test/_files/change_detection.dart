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
  selector: 'component-state',
  template: '<div>Stateful</div>',
)
class LegacyComponentState extends ComponentState {}

@Component(
  selector: 'default',
  template: '<div>Default</div>',
)
class DefaultComponent {}

@Component(
  selector: 'uses-ng-model',
  directives: [
    NgModelLike,
  ],
  template: '<input [(ngModel)]="value" />',
)
class UsesNgModelLike {
  var value = 'Hello World';
}

@Directive(
  selector: '[ngModel]:not([ngControl]):not([ngFormControl])',
)
class NgModelLike implements AfterChanges, OnInit {
  @Output('ngModelChange')
  Stream<void> get modelChange => const Stream.empty();

  @Input('ngModel')
  set model(Object ngModel) {}

  @override
  void ngAfterChanges() {}

  @override
  void ngOnInit() {}
}

@Component(
  selector: 'uses-do-check-on-push',
  template: '<cd-on-push-do-check [name]="name"></cd-on-push-do-check>',
  directives: [DoCheckOnPushComponent],
)
class UsesDoCheckOnPushComponent {
  String name;
}

@Component(
  selector: 'cd-on-push-do-check',
  template: 'Name: {{name}}',
  changeDetection: ChangeDetectionStrategy.OnPush,
)
class DoCheckOnPushComponent implements DoCheck {
  @Input()
  String name;

  @override
  void ngDoCheck() {}
}
