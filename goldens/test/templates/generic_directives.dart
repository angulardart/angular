@JS()
library golden;

import 'package:js/js.dart';
import 'package:angular/angular.dart';

import 'generic_directives.template.dart' as ng;

/// Avoids Dart2JS thinking something is constant/unchanging.
@JS()
external T deopt<T>([Object? any]);

void main() {
  runApp(ng.createGoldenComponentFactory());
}

@Component(
  selector: 'golden',
  directives: [
    UsesUntypedComp,
    UsesGenericComp,
    UsesGenericCompGeneric,
    UsesMappingComp1,
    UsesMappingComp2,
    UsesBoundCompWithBounds,
    UsesFunctionTypeComp,
    UsesNestedParentComp,
    UsesMultipleTypesComp,
    UsesGenericChangeDetector,
  ],
  template: '''
    <uses-unyped-comp></uses-unyped-comp>
    <uses-generic-comp></uses-generic-comp>
    <uses-generic-comp-generic></uses-generic-comp-generic>
    <uses-mapping-comp-1></uses-mapping-comp-1>
    <uses-mapping-comp-2></uses-mapping-comp-2>
    <uses-bound-comp-with-bounds></uses-bound-comp-with-bounds>
    <uses-function-type-comp></uses-function-type-comp>
    <uses-nested-parent-comp></uses-nested-parent-comp>
    <uses-multiple-types-comp></uses-multiple-types-comp>
    <uses-generic-change-detector></uses-generic-change-detector>
  ''',
)
class GoldenComponent {}

/// A component with no generic type parameters.
@Component(
  selector: 'comp',
  template: '',
)
class UntypedComp {
  @Input()
  dynamic input;
}

/// A component that uses [UntypedComp].
@Component(
  selector: 'uses-unyped-comp',
  directives: [
    UntypedComp,
  ],
  template: '<comp [input]="binding"></comp>',
)
class UsesUntypedComp {
  int binding = deopt();
}

/// A component with a single generic type parameter.
@Component(
  selector: 'comp',
  template: '',
)
class GenericComp<T> {
  @Input()
  T? input;
}

/// A component that uses [GenericComp].
@Component(
  selector: 'uses-generic-comp',
  directives: [
    GenericComp,
  ],
  directiveTypes: [
    Typed<GenericComp<int>>(),
  ],
  template: '<comp [input]="binding"></comp>',
)
class UsesGenericComp {
  int binding = deopt();
}

// A generic component that uses [GenericComp]
@Component(
  selector: 'uses-generic-comp-generic',
  directives: [
    GenericComp,
  ],
  directiveTypes: [
    Typed<GenericComp<void>>.of([
      Typed<List<void>>.of([#E])
    ])
  ],
  template: '<comp [input]="binding"></comp>',
)
class UsesGenericCompGeneric<E> {
  List<E> binding = deopt();
}

/// A component with two type parameters, each with a separate `@Input()`.
@Component(
  selector: 'comp',
  template: '',
)
class MappingComp1<K, V> {
  @Input()
  K? key;

  @Input()
  V? value;
}

/// A component that uses [MappingComp1].
@Component(
  selector: 'uses-mapping-comp-1',
  directives: [
    MappingComp1,
  ],
  directiveTypes: [
    Typed<MappingComp1<int, String>>(),
  ],
  template: '<comp [key]="bindKey" [value]="bindValue"></comp>',
)
class UsesMappingComp1 {
  int bindKey = deopt();
  String bindValue = deopt();
}

/// A component with two type parameters, but with a single `@Input()`.
@Component(
  selector: 'comp',
  template: '',
)
class MappingComp2<K, V> {
  @Input()
  Map<K, V>? input;
}

/// A component that uses [MappingComp2].
@Component(
  selector: 'uses-mapping-comp-2',
  directives: [
    MappingComp2,
  ],
  directiveTypes: [
    Typed<MappingComp2<int, String>>(),
  ],
  template: '<comp [input]="binding"></comp>',
)
class UsesMappingComp2 {
  Map<int, String> binding = deopt();
}

/// A component with a type parameter with bounds other than `dynamic`.
@Component(
  selector: 'comp',
  template: '',
)
class BoundComp<T extends num> {
  @Input()
  T? input;
}

/// A component that uses [BoundComp].
@Component(
  selector: 'uses-bound-comp-with-bounds',
  directives: [
    BoundComp,
  ],
  template: '<comp [input]="binding"></comp>',
)
class UsesBoundCompWithBounds {
  // Intentionally left as 'null', we want to use <num> as the type.
  var binding = deopt();
}

/// A component that uses [BoundComp] with an explicit type.
@Component(
  selector: 'comp',
  directives: [
    BoundComp,
  ],
  template: '<comp [input]="binding"></comp>',
)
class UsesBoundComp {
  num binding = deopt();
}

/// A component with a type parameter that is bound by another one.
@Component(
  selector: 'comp',
  template: '',
)
class SelfBoundComp<A, B extends A> {
  @Input()
  A? a;

  @Input()
  B? b;
}

/// A component that uses [SelfBoundComp].
@Component(
  selector: 'comp',
  directives: [
    SelfBoundComp,
  ],
  template: '<comp [a]="bindA" [b]="bindB"></comp>',
)
class UsesSelfBoundComp {
  num bindA = deopt();
  int bindB = deopt();
}

/// A component that uses function type signatures.
@Component(
  selector: 'comp',
  template: '',
)
class FunctionTypeComp<F> {
  @Input()
  void Function(F)? input;
}

/// A component that uses [FunctionTypeComp].
@Component(
  selector: 'uses-function-type-comp',
  directives: [
    FunctionTypeComp,
  ],
  directiveTypes: [
    Typed<FunctionTypeComp<String>>(),
  ],
  template: '<comp [input]="binding"></comp>',
)
class UsesFunctionTypeComp {
  var binding = _function;
  static void _function(String name) {
    deopt(name);
  }
}

/// A component that has a child component that needs its generic type.
@Component(
  selector: 'parent',
  directives: [
    NestedChildComp,
    NgFor,
  ],
  directiveTypes: [
    Typed<NestedChildComp<void>>.of([#T]),
  ],
  template: r'''
    <child [input]="input1"></child>
    <child [input]="input2"></child>
    <child *ngFor="let input of moreInputs" [input]="input"></child>
  ''',
)
class NestedParentComp<T> {
  @Input()
  T? input1;

  @Input()
  T? input2;

  @Input()
  Iterable<T>? moreInputs;
}

@Component(
  selector: 'child',
  template: '',
)
class NestedChildComp<T> {
  @Input()
  T? input;
}

/// A component that uses [NestedParentComp].
@Component(
  selector: 'uses-nested-parent-comp',
  directives: [
    NestedParentComp,
  ],
  directiveTypes: [
    Typed<NestedParentComp<int>>(),
  ],
  template: r'''
    <parent
      [input1]="binding1"
      [input2]="binding2"
      [moreInputs]="moreBindings">
    </parent>
  ''',
)
class UsesNestedParentComp {
  int binding1 = deopt();
  int binding2 = deopt();
  List<int> moreBindings = deopt();
}

@Component(
  selector: 'uses-multiple-types-comp',
  directives: [
    GenericComp,
  ],
  directiveTypes: [
    Typed<GenericComp<int>>(on: 'indexed'),
    Typed<GenericComp<String>>(),
  ],
  template: '''
    <comp [input]="name"></comp>
    <comp [input]="index" #indexed></comp>
  ''',
)
class UsesMultipleTypesComp {
  String name = deopt();
  int index = deopt();
}

@Directive(selector: '[generic]')
class GenericDirective<T extends String> {
  @Input()
  @HostBinding('attr.a')
  T? input;
}

@Component(
  selector: 'uses-generic-change-detector',
  directives: [
    GenericDirective,
  ],
  directiveTypes: [
    Typed<GenericDirective<String>>(),
  ],
  template: '<div generic [input]="value"></div>',
)
class UsesGenericChangeDetector {
  String value = deopt();
}
