import 'dart:html' as html;

import 'package:angular/angular.dart';

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
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class InjectableComponent {
  final BaseService service;

  // ignore: deprecated_member_use
  final InjectableService _injectableService;
  final bool isTest;

  InjectableComponent(
      @Attribute('baseService') @optional this.service,
      // ignore: deprecated_member_use
      @Optional() InjectableService injectableService,
      @Inject(testToken) this.isTest,
      [String foo])
      : _injectableService = injectableService;

  // ignore: deprecated_member_use
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

class XsrfToken extends OpaqueToken<String> {
  const XsrfToken();
}

@Injectable()
class InjectsXsrfToken {
  InjectsXsrfToken(@XsrfToken() String token);
}
