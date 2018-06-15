import 'package:angular/angular.dart';

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
  selector: 'comp',
  directives: [
    UntypedComp,
  ],
  template: '<comp [input]="binding"></comp>',
)
class UsesUntypedComp {
  var binding = 5;
}

/// A component with a single generic type parameter.
@Component(
  selector: 'comp',
  template: '',
)
class GenericComp<T> {
  @Input()
  T input;
}

/// A component that uses [GenericComp].
@Component(
  selector: 'comp',
  directives: [
    GenericComp,
  ],
  template: '<comp [input]="binding"></comp>',
)
class UsesGenericComp {
  var binding = 5;
}

/// A component with two type parameters, each with a separate `@Input()`.
@Component(
  selector: 'comp',
  template: '',
)
class MappingComp1<K, V> {
  @Input()
  K key;

  @Input()
  V value;
}

/// A component that uses [MappingComp1].
@Component(
  selector: 'comp',
  directives: [
    MappingComp1,
  ],
  template: '<comp [key]="bindKey" [value]="bindValue"></comp>',
)
class UsesMappingComp1 {
  var key = 5;
  var value = 'Hello';
}

/// A component with two type parameters, but with a single `@Input()`.
@Component(
  selector: 'comp',
  template: '',
)
class MappingComp2<K, V> {
  @Input()
  Map<K, V> input;
}

/// A component that uses [MappingComp2].
@Component(
  selector: 'comp',
  directives: [
    MappingComp2,
  ],
  template: '<comp [input]="binding"></comp>',
)
class UsesMappingComp2 {
  var binding = {5: 'Hello'};
}

/// A component with a type parameter with bounds other than `dynamic`.
@Component(
  selector: 'comp',
  template: '',
)
class BoundComp<T extends num> {
  @Input()
  T input;
}

/// A component that uses [BoundComp].
@Component(
  selector: 'comp',
  directives: [
    BoundComp,
  ],
  template: '<comp [input]="binding"></comp>',
)
class UsesBoundCompWithBounds {
  // Intentionally left as 'null', we want to use <num> as the type.
  var binding;
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
  var binding = 5;
}

/// A component with a type parameter that is bound by another one.
@Component(
  selector: 'comp',
  template: '',
)
class SelfBoundComp<A, B extends A> {
  @Input()
  A a;

  @Input()
  B b;
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
  num bindA = 5;
  int bindB = 10;
}

/// A component with a type parameter that is recursive.
@Component(
  selector: 'comp',
  template: '',
)
class RecursiveComp<T extends Comparable<T>> {
  @Input()
  T input;
}

/// A component that uses [RecursiveComp].
@Component(
  selector: 'comp',
  directives: [
    RecursiveComp,
  ],
  template: '<comp [input]="binding"></comp>',
)
class UsesRecursiveComp {
  var input = 5;
}

/// A component that uses function type signatures.
@Component(
  selector: 'comp',
  template: '',
)
class FunctionTypeComp<F> {
  @Input()
  void Function(F) input;
}

/// A component that uses [FunctionTypeComp].
@Component(
  selector: 'comp',
  directives: [
    FunctionTypeComp,
  ],
  template: '<comp [input]="binding"></comp>',
)
class UsesFunctionTypeComp {
  var binding = _function;
  static void _function(String name) {}
}

/// A component that has a child component that needs its generic type.
@Component(
  selector: 'parent',
  directives: [
    NestedChildComp,
    NgFor,
  ],
  template: r'''
    <child [input]="input1"></child>
    <child [input]="input2"></child>
    <child *ngFor="let input of moreInputs" [input]="input"></child>
  ''',
)
class NestedParentComp<T> {
  @Input()
  T input1;

  @Input()
  T input2;

  @Input()
  Iterable<T> moreInputs;
}

@Component(
  selector: 'child',
  template: '',
)
class NestedChildComp<T> {
  @Input()
  T input;
}

/// A component that uses [NestedParentComp].
@Component(
  selector: 'comp',
  directives: [
    NestedParentComp,
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
  var binding1 = 1;
  var binding2 = 2;
  var moreBindings = [3, 4, 5];
}
