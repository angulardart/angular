import 'package:angular/angular.dart' as angular;

// This is silly, but just for simplified testing.
import 'import_prefixes.dart' as prefixed;

@angular.Component(
  selector: 'parent-comp',
  directives: [
    prefixed.ChildComponent,
  ],
  template: '<child-comp [myType]="input"></child-comp>',
)
class ParentComponent {
  final input = new prefixed.MyType();
}

@angular.Component(
  selector: 'child-cmp',
  template: r'''
    {{myType}}
  ''',
)
class ChildComponent {
  @angular.Input()
  prefixed.MyType myType;
}

class MyType {}
