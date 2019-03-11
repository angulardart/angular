@TestOn('browser')
import 'package:test/test.dart';
import 'package:angular/angular.dart';
import 'package:angular_test/angular_test.dart';

import '908_analyzer_inference_test.template.dart' as ng_generated;

void main() {
  NgTestBed<SomeInterface> testBed;
  NgTestFixture<SomeInterface> fixture;
  List<Object> interfaces;

  tearDown(disposeAnyRunningTest);

  test('should correctly type an implicit Provider', () async {
    testBed = NgTestBed.forComponent(
      ng_generated.CompProvidesImplicitTypesNgFactory,
    );
    fixture = await testBed.create();

    interfaces = fixture.assertOnlyInstance.injector.get(someInterfaces);
    expect(interfaces, isNotEmpty);
    expect(
      interfaces,
      isTypedList,
    );
  });

  test('should correctly type an explicit provider', () async {
    testBed = NgTestBed.forComponent(
      ng_generated.CompProvidesExplicitTypesNgFactory,
    );
    fixture = await testBed.create();

    interfaces = fixture.assertOnlyInstance.injector.get(someInterfaces);
    expect(interfaces, isNotEmpty);
    expect(
      interfaces,
      isTypedList,
    );
  });
}

const isTypedList = TypeMatcher<List<SomeInterface>>();
const someInterfaces = MultiToken<SomeInterface>('someInterfaces');

abstract class SomeInterface {
  Injector get injector;
}

@Component(
  selector: 'comp-provides-implicit-types',
  providers: [
    ExistingProvider /* IMPLICIT: <SomeInterface> */ .forToken(
      someInterfaces,
      CompProvidesImplicitTypes,
    ),
  ],
  template: '',
)
class CompProvidesImplicitTypes implements SomeInterface {
  @override
  final Injector injector;

  CompProvidesImplicitTypes(this.injector);
}

@Component(
  selector: 'comp-provides-explicit-types',
  providers: [
    ExistingProvider<List<SomeInterface>>.forToken(
      someInterfaces,
      CompProvidesExplicitTypes,
    ),
  ],
  template: '',
)
class CompProvidesExplicitTypes implements SomeInterface {
  @override
  final Injector injector;

  CompProvidesExplicitTypes(this.injector);
}
