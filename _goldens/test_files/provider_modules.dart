import 'package:angular/angular.dart';

@Injectable()
class FooService {}

const fooProviders = const [
  FooService,
];

const fooToken = const OpaqueToken('fooToken');
const barToken = const OpaqueToken('barToken');
const bazToken = const OpaqueToken('bazToken');

const List<String> someValues = const ['a', 'b', 'c'];

@Injectable()
List<String> getSomeValues() => someValues;

const barProviders = const [
  fooProviders,
  const Provider(fooToken, useValue: const Duration(seconds: 500)),
  const Provider(barToken, useValue: someValues),
  const Provider(bazToken, useFactory: getSomeValues),
];

@Component(
  selector: 'provider-modules',
  providers: const [barProviders],
  template: '',
)
class ProviderModulesComponent {}
