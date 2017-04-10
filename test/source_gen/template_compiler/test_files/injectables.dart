import 'dart:html' as html;

import 'package:angular2/angular2.dart';

@Component(
  selector: 'test-injectables',
  template: '<div>Inject!</div>',
  providers: const [
    const Provider(testToken, useFactory: injectableFactory),
    const Provider(
      SomeDep,
      useFactory: createLinkedHashMap,
      deps: const [testToken],
    ),
    const Provider(
      BaseService,
      useFactory: createLinkedHashMap,
      deps: const [
        const [SomeDep, const Self()],
        const [SomeDep, const SkipSelf()],
        const [SomeDep, const Optional()],
      ],
    ),
  ],
)
class InjectableComponent {
  final BaseService service;
  final InjectableService _injectableService;
  final bool isTest;

  InjectableComponent(
      @Attribute("baseService") @optional this.service,
      @Optional() InjectableService injectableService,
      @Inject(testToken) this.isTest,
      [String foo])
      : _injectableService = injectableService;

  InjectableService get injectableService => _injectableService;
}

const Optional optional = const Optional();

@Injectable()
class SomeDep {}

@Injectable()
class BaseService {
  BaseService._();

  factory BaseService() {
    return new BaseService._();
  }
}

@Injectable()
@Deprecated('Testing deprecation')
class InjectableService {}

const testToken = const OpaqueToken('test');

@Injectable()
bool injectableFactory(html.Window value) => value != null;

createLinkedHashMap(string) => {string: 'Hello World'};
