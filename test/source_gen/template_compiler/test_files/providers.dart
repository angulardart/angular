import 'package:angular2/angular2.dart';

@Component(selector: 'providers', template: 'Hello', providers: const [
  MyTypeAnnotation,
  const Provider(
    MyUseFactory,
    useFactory: ProvidersComponent.createService,
  ),
  const Provider(
    MyUseClass,
    useClass: MyUseClass,
  ),
  const Provider(
    MyUseExisting,
    useExisting: MyUseClass,
  ),
  const Provider(
    MyUseExistingNested,
    useExisting: MyUseExisting,
  ),
  const Provider(
    MyUseValue,
    useValue: const MyUseValue('Andrew'),
  ),
  const Provider(
    useValueString,
    useValue: 'foo',
  ),
  const Provider(
    MyMulti,
    multi: true,
  ),
  const Provider(useValueList, useValue: const [
    const MyUseValue('Andrew'),
    const MyUseValue('Matan'),
    const MyUseValue.named(optional: true)
  ]),
  const Provider(const OpaqueToken('useEnums'), useValue: MyEnum.first),
], viewProviders: const [
  const Provider(MyUseValue, useValue: const MyUseValue('Matan'))
])
class ProvidersComponent {
  static MyUseFactory createService(NgZone ngZone, {bool optional}) =>
      new MyUseFactory();
}

class MyTypeAnnotation {}

class MyUseExisting {}

class MyUseClass implements MyUseExisting {}

class MyUseExistingNested implements MyUseExisting {}

class MyUseFactory {}

class MyUseValue {
  const MyUseValue(String name);

  const MyUseValue.named({bool optional});
}

class MyMulti {}

const useValueString = const OpaqueToken('useValueString');
const useValueList = const OpaqueToken('useValueList');

enum MyEnum { first, second }
