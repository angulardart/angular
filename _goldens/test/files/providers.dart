import 'package:angular/angular.dart';

@Component(
  selector: 'providers',
  template: 'Hello',
  providers: [
    MyTypeAnnotation,
    MyInjectableTypeAnnotation,
    Provider(
      MyUseFactory,
      useFactory: ProvidersComponent.createService,
    ),
    Provider(
      MyUseClass,
      useClass: MyUseClass,
    ),
    Provider(
      MyUseExisting,
      useExisting: MyUseClass,
    ),
    Provider(
      MyUseExistingNested,
      useExisting: MyUseExisting,
    ),
    Provider(
      MyUseValue,
      useValue: MyUseValue('Andrew'),
    ),
    Provider(
      useValueString,
      useValue: 'foo',
    ),
    Provider(useValueList, useValue: [
      MyUseValue('Andrew'),
      MyUseValue('Matan'),
      MyUseValue.named(optional: true)
    ]),
    Provider(useValueMap, useValue: {
      'Andrew': MyUseValue('Andrew'),
      'Matan': MyUseValue('Matan')
    }),
    Provider(OpaqueToken('useEnums'), useValue: MyEnum.first),
    Provider(XsrfToken(), useValue: 'ABC123'),
  ],
  viewProviders: [Provider(MyUseValue, useValue: MyUseValue('Matan'))],
)
class ProvidersComponent {
  static MyUseFactory createService(NgZone ngZone, {bool optional}) =>
      MyUseFactory();
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

const useValueString = OpaqueToken('useValueString');
const useValueList = OpaqueToken('useValueList');
const useValueMap = OpaqueToken('useValueMap');

enum MyEnum { first, second }

class XsrfToken extends OpaqueToken<String> {
  const XsrfToken();
}
