import 'package:angular/angular.dart';

abstract class Interface {}

@Component(
  selector: 'child',
  template: '',
  changeDetection: ChangeDetectionStrategy.OnPush,
  providers: [
    ExistingProvider(Interface, Child),
  ],
)
class Child implements Interface {}

@Component(
  selector: 'query',
  template: '''
    <ng-content></ng-content>
    <child></child>
    <child *ngIf="isVisible"></child>
  ''',
  directives: [Child, NgIf],
)
class Query {
  var isVisible = false;

  @ContentChildren(Child)
  List<Child> contentChildren;

  @ViewChild(Interface)
  Interface viewInterface;

  @ViewChildren(Child)
  List<Child> viewChildren;
}

@Component(
  selector: 'test',
  template: '''
    <query>
      <child></child>
      <child></child>
    </query>
  ''',
  directives: [Child, Query],
)
class Test {}
