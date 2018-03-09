import 'package:angular/angular.dart';
import 'package:angular_router/angular_router.dart';
import 'package:http/http.dart';
import 'package:http/browser_client.dart';
import 'package:pwa/client.dart' as pwa;

// We are ignoring files that will be generated at compile-time.
// ignore: uri_has_not_been_generated
import 'package:examples.hacker_news_pwa/app_component.template.dart' as app;
import 'package:examples.hacker_news_pwa/hacker_news_service.dart';

// We are ignoring files that will be generated at compile-time.
// ignore: uri_has_not_been_generated
import 'main.template.dart' as ng;

@GenerateInjector(const [
  // HTTP and Services.
  const ClassProvider(HackerNewsService),
  const FactoryProvider(BaseClient, createBrowserClient),
  const ValueProvider.forToken(baseUrl, defaultBaseUrl),

  // SPA Router.
  routerProviders,
])
final InjectorFactory hackerNewsApp = ng.hackerNewsApp$Injector;

BrowserClient createBrowserClient() => new BrowserClient();

void main() {
  // Install service worker.
  new pwa.Client();

  // Start AngularDart.
  runApp(
    app.AppComponentNgFactory,
    createInjector: hackerNewsApp,
  );
}
