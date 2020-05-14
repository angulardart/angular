import 'package:angular/angular.dart' as angular;

// This is silly, but just for simplified testing.
import 'import_prefixes.dart' as prefixed;
import 'import_prefixes.dart' as prefixed2 show ChildComponent;
import 'import_prefixes.dart' as prefixed3 hide ChildComponent;

@angular.Component(
  selector: 'parent-comp',
  directives: [
    prefixed2.ChildComponent,
  ],
  template: '<child-comp [myType]="input"></child-comp>',
)
class ParentComponent {
  final input = prefixed.MyType();
}

@angular.Component(
  selector: 'child-comp',
  template: r'''
    {{myType}}
  ''',
)
class ChildComponent {
  @angular.Input()
  prefixed3.MyType myType;
}

class MyType {}
