import 'package:angular/angular.dart';

@Component(
  selector: 'providers',
  template: 'Hello',
  providers: const [
    MyTypeAnnotation,
    MyInjectableTypeAnnotation,
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
    const Provider(useValueList, useValue: const [
      const MyUseValue('Andrew'),
      const MyUseValue('Matan'),
      const MyUseValue.named(optional: true)
    ]),
    const Provider(useValueMap, useValue: const {
      'Andrew': const MyUseValue('Andrew'),
      'Matan': const MyUseValue('Matan')
    }),
    const Provider(const OpaqueToken('useEnums'), useValue: MyEnum.first),
  ],
  viewProviders: const [
    const Provider(MyUseValue, useValue: const MyUseValue('Matan'))
  ],
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class ProvidersComponent {
  static MyUseFactory createService(NgZone ngZone, {bool optional}) =>
      new MyUseFactory();
}

class MyTypeAnnotation {}

@Injectable()
class MyInjectableTypeAnnotation {}

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
const useValueMap = const OpaqueToken('useValueMap');

enum MyEnum { first, second }
