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
class NgModelLike extends Object
    with ComponentState
    implements AfterChanges, DoCheck, OnInit {
  @Output('ngModelChange')
  get modelChange => null;

  @Input('ngModel')
  set model(Object ngModel) {}

  @override
  void ngAfterChanges() {}

  @override
  void ngDoCheck() {}

  @override
  void ngOnInit() {}
}
