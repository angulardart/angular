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
        const [null]
      ],
    );
    expect(
      fixture.assertOnlyInstance.aListOfListOfVoid,
      const [
        const [2]
      ],
    );
  });

  test('should support void and Null in a @GenerateInjector', () {
    final injector = generatedInjector();
    expect(injector.get(listOfNull), const [null]);
    expect(injector.get(listOfVoid), const [1]);
    expect(injector.get(listOfListOfNull), const [
      const [null]
    ]);
    expect(injector.get(listOfListOfVoid), const [
      const [2]
    ]);
  });
}

const listOfVoid = const OpaqueToken<List<void>>('listOfVoid');
const listOfNull = const OpaqueToken<List<Null>>('listOfNull');
const listOfListOfVoid = const MultiToken<List<void>>('listOfListOfVoid');
const listOfListOfNull = const MultiToken<List<Null>>('listOfListOfNull');

const _testProviders = const [
  const ValueProvider.forToken(listOfVoid, const [1]),
  const ValueProvider.forToken(listOfNull, const [null]),
  const ValueProvider.forToken(listOfListOfVoid, const [2]),
  const ValueProvider.forToken(listOfListOfNull, const [null]),
];

@GenerateInjector(const [_testProviders])
final InjectorFactory generatedInjector = ng.generatedInjector$Injector;

@Component(
  selector: 'comp',
  providers: const [_testProviders],
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
