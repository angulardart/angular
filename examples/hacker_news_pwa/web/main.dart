import 'package:angular/angular.dart';
import 'package:angular/experimental.dart';
import 'package:angular_router/angular_router.dart';
import 'package:pwa/client.dart' as pwa;

// ignore: uri_has_not_been_generated
import 'package:examples.hacker_news_pwa/app_component.template.dart' as app;
import 'package:examples.hacker_news_pwa/hacker_news_service.dart';

// ignore: uri_has_not_been_generated
import 'main.template.dart' as ng;

@GenerateInjector(const [
  HackerNewsService,
  routerProviders,
])
final InjectorFactory hackerNewsApp = ng.hackerNewsApp$Injector;

void main() {
  // Install service worker.
  new pwa.Client();
  bootstrapFactory(
    app.AppComponentNgFactory,
    hackerNewsApp,
  );
}
