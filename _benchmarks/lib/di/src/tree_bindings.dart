import 'package:angular/angular.dart';

const numberOfPages = 3;
const numberOfTabs = 5;

/// Represents application-level bindings for a simple tree-like application.
const simpleTreeAppBindings = const [
  AppService,
  RpcService,
  const Provider(Cache, useClass: InMemoryCache),
  intlServices,
];

const intlServices = const [
  IntlService,
  const Provider(
    supportedLanguages,
    useValue: const LanguageService('sq_AL'),
    multi: true,
  ),
  const Provider(
    supportedLanguages,
    useValue: const LanguageService('ar_DZ'),
    multi: true,
  ),
  const Provider(
    supportedLanguages,
    useValue: const LanguageService('ar_BH'),
    multi: true,
  ),
  const Provider(
    supportedLanguages,
    useValue: const LanguageService('ar_EG'),
    multi: true,
  ),
  const Provider(
    supportedLanguages,
    useValue: const LanguageService('ar_IQ'),
    multi: true,
  ),
];

@Injectable()
class AppService {
  AppService(RpcService p1, IntlService p2);
}

@Injectable()
class RpcService {
  RpcService(Cache p1);
}

abstract class Cache {}

@Injectable()
class InMemoryCache implements Cache {}

@Injectable()
class IntlService {
  IntlService(@Inject(supportedLanguages) List<dynamic> p1);
}

const supportedLanguages = const OpaqueToken('languages');

class LanguageService {
  const LanguageService(String locale);
}

/// Represents page-level bindings for a simple tree-like application.
///
/// Pages may be nested (i.e pages within pages).
const simpleTreePageBindings = const [
  PageService,
  const Provider(TabControllerService, useExisting: PageService),
  BusinessService,
];

@Injectable()
class PageService implements TabControllerService {
  PageService(
    @Optional() @SkipSelf() PageService p1,
    AppService p2,
    BusinessService p3,
    @Inject(supportedLanguages) List<dynamic> supportedLanguages,
  );
}

@Injectable()
class BusinessService {
  BusinessService(RpcService p1, IntlService p2);
}

abstract class TabControllerService {}

/// Represents tab-panel-level bindings for a simple tree-like application.
const simpleTreePanelBindings = const [
  PanelService,
];

@Injectable()
class PanelService {
  PanelService(TabControllerService p1, IntlService p2);
}

/// Represents tap-button-level bindings for a simple tree-like application.
const simpleTreeTabBindings = const [
  TabService,
];

@Injectable()
class TabService {
  TabService(PanelService p1);
}
