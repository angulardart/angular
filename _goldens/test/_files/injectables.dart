import 'dart:html' as html;

import 'package:angular/angular.dart';

@Component(
  selector: 'test-injectables',
  template: '<div>Inject!</div>',
  providers: [
    Provider(testToken, useFactory: injectableFactory),
    Provider(
      SomeDep,
      useFactory: createLinkedHashMap,
      deps: [testToken],
    ),
    Provider(
      BaseService,
      useFactory: createLinkedHashMap,
      deps: [
        [SomeDep, Self()],
        [SomeDep, SkipSelf()],
        [SomeDep, Optional()],
      ],
    ),
  ],
)
class InjectableComponent {
  final String service;
  final InjectableService _injectableService;
  final bool isTest;

  InjectableComponent(
      @Attribute('baseService') @optional this.service,
      @Optional() InjectableService injectableService,
      @Inject(testToken) this.isTest,
      [String foo])
      : _injectableService = injectableService;

  InjectableService get injectableService => _injectableService;
}

const Optional optional = Optional();

@Injectable()
class SomeDep {}

@Injectable()
class BaseService {
  BaseService._();

  factory BaseService() {
    return BaseService._();
  }
}

@Injectable()
@Deprecated('Testing deprecation')
class InjectableService {}

const testToken = OpaqueToken('test');

@Injectable()
bool injectableFactory(html.Window value) => value != null;

createLinkedHashMap(string) => {string: 'Hello World'};

class XsrfToken extends OpaqueToken<String> {
  const XsrfToken();
}

@Injectable()
class InjectsXsrfToken {
  InjectsXsrfToken(@XsrfToken() String token);
}
