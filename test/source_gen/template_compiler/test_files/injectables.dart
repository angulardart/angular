import 'package:angular2/angular2.dart';

@Component(selector: 'test-injectables', template: '<div>Inject!</div>')
class InjectableComponent {
  final BaseService service;
  final InjectableService _injectableService;

  InjectableComponent(@Attribute("baseService") @optional this.service,
      @Optional() InjectableService injectableService)
      : _injectableService = injectableService;

  InjectableService get injectableService => _injectableService;
}

const Optional optional = const Optional();

@Injectable()
class BaseService {}

@Injectable()
class InjectableService {}
