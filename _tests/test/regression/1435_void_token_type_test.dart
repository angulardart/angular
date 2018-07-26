@TestOn('browser')
import 'package:angular/angular.dart';
import 'package:angular_test/angular_test.dart';
import 'package:test/test.dart';

import '1435_void_token_type_test.template.dart' as ng;

// Yes, a `2` can represent a `void`.
//
// The only reason I'm using numbers in this test is in order to make sure that
// void is treated separately from Null.
void main() {
  test('should support void and Null in a @Component', () async {
    final fixture = await NgTestBed.forComponent(
      ng.ComponentInjectorNgFactory,
    ).create();
    expect(
      fixture.assertOnlyInstance.aListOfNull,
      const [null],
    );
    expect(
      fixture.assertOnlyInstance.aListOfVoid,
      const [1],
    );
    expect(
      fixture.assertOnlyInstance.aListOfListOfNull,
      const [
        [null]
      ],
    );
    expect(
      fixture.assertOnlyInstance.aListOfListOfVoid,
      const [
        [2]
      ],
    );
  });

  test('should support void and Null in a @GenerateInjector', () {
    final injector = generatedInjector();
    expect(injector.get(listOfNull), const [null]);
    expect(injector.get(listOfVoid), const [1]);
    expect(injector.get(listOfListOfNull), const [
      [null]
    ]);
    expect(injector.get(listOfListOfVoid), const [
      [2]
    ]);
  });
}

const listOfVoid = OpaqueToken<List<void>>('listOfVoid');
const listOfNull = OpaqueToken<List<Null>>('listOfNull');
const listOfListOfVoid = MultiToken<List<void>>('listOfListOfVoid');
const listOfListOfNull = MultiToken<List<Null>>('listOfListOfNull');

const _testProviders = [
  ValueProvider.forToken(listOfVoid, [1]),
  ValueProvider.forToken(listOfNull, [null]),
  ValueProvider.forToken(listOfListOfVoid, [2]),
  ValueProvider.forToken(listOfListOfNull, [null]),
];

@GenerateInjector([_testProviders])
final InjectorFactory generatedInjector = ng.generatedInjector$Injector;

@Component(
  selector: 'comp',
  providers: [_testProviders],
  template: '',
)
class ComponentInjector {
  // Lack of types on these fields (i.e. List<void> or List<Null>) is due to
  // https://github.com/dart-lang/angular/issues/1436
  final Object aListOfVoid;
  final Object aListOfNull;

  final List<List<void>> aListOfListOfVoid;
  final List<List<Null>> aListOfListOfNull;

  ComponentInjector(
    @Inject(listOfVoid) this.aListOfVoid,
    @Inject(listOfNull) this.aListOfNull,
    @Inject(listOfListOfVoid) this.aListOfListOfVoid,
    @Inject(listOfListOfNull) this.aListOfListOfNull,
  );
}
