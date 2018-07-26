import 'package:angular/angular.dart';

@Injectable()
class FooService {}

const fooProviders = [
  FooService,
];

const fooToken = OpaqueToken('fooToken');
const barToken = OpaqueToken('barToken');
const bazToken = OpaqueToken('bazToken');

const List<String> someValues = ['a', 'b', 'c'];

@Injectable()
List<String> getSomeValues() => someValues;

const barProviders = [
  fooProviders,
  Provider(fooToken, useValue: Duration(seconds: 500)),
  Provider(barToken, useValue: someValues),
  Provider(bazToken, useFactory: getSomeValues),
];

@Component(
  selector: 'provider-modules',
  providers: [barProviders],
  template: '',
)
class ProviderModulesComponent {}
