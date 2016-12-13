import 'package:angular2/angular2.dart';

@Component(
    selector: 'test-injectables',
    template: '<div>Inject!</div>',
    providers: const [const Provider(testToken, useFactory: injectableFactory)])
class InjectableComponent {
  final BaseService service;
  final InjectableService _injectableService;
  final bool isTest;

  InjectableComponent(
      @Attribute("baseService") @optional this.service,
      @Optional() InjectableService injectableService,
      // TODO(alorenzen): Replace bool with testToken once we can support
      // [OpaqueToken]s.
      @Inject(bool) this.isTest)
      : _injectableService = injectableService;

  InjectableService get injectableService => _injectableService;
}

const Optional optional = const Optional();

@Injectable()
class BaseService {}

@Injectable()
class InjectableService {}

const testToken = const OpaqueToken('test');

@Injectable()
bool injectableFactory(String value) => value != null;
