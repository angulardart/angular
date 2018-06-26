import 'dart:async';
import 'dart:html';

import 'package:angular/angular.dart';
import 'package:angular_router/angular_router.dart';
import 'package:pwa/client.dart' as pwa;

// We are ignoring files that will be generated at compile-time.
// ignore: uri_has_not_been_generated
import 'package:examples.hacker_news_pwa/app_component.template.dart' as app;
import 'package:examples.hacker_news_pwa/hacker_news_service.dart';

// We are ignoring files that will be generated at compile-time.
// ignore: uri_has_not_been_generated
import 'main.template.dart' as ng;

@GenerateInjector([
  // HTTP and Services.
  FactoryProvider(HackerNewsService, getNewsService),

  // SPA Router.
  routerProviders,
])
final InjectorFactory hackerNewsApp = ng.hackerNewsApp$Injector;

HackerNewsService _service;
HackerNewsService getNewsService() => _service;

void main() {
  // Start fetching the articles if we are a first time viewer.
  //
  // This will make the perceived first load faster, and allow us to avoid
  // a flash-of-unstyled-content (Loading...) for the initial load, which hurts
  // PWA scores.
  _service = HackerNewsService(defaultBaseUrl);
  Future future;
  final path = window.location.pathname;
  if (window.location.search.isEmpty && !path.startsWith('/item')) {
    var feed = path.split('/').last;
    if (feed.isEmpty) {
      feed = 'news';
    }
    future = _service.getFeed(feed, 1);
  }

  // Install service worker.
  pwa.Client();

  // Start app after fetched.
  future.then((_) {
    runApp(
      app.AppComponentNgFactory,
      createInjector: hackerNewsApp,
    );
  });
}
