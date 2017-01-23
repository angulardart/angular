import 'package:angular2/angular2.dart';

@Component(
  selector: 'providers',
  template: 'Hello',
  providers: const [
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
      MyUseValue,
      useValue: const MyUseValue('Andrew'),
    ),
  ],
)
class ProvidersComponent {
  static MyUseFactory createService(NgZone ngZone) => new MyUseFactory();
}

class MyUseExisting {}

class MyUseClass implements MyUseExisting {}

class MyUseFactory {}

class MyUseValue {
  const MyUseValue(String name);
}
