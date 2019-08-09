import 'dart:async';
import 'dart:html';

import 'package:angular/angular.dart';
import 'package:angular_router/angular_router.dart';
import 'package:examples.hacker_news_pwa/pwa/shim_client.dart';

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

final _service = HackerNewsService(defaultBaseUrl);
HackerNewsService getNewsService() => _service;

ComponentRef<void> _rootComponentRef;

/// DDC hot restart hook.
void onReloadStart() {
  _rootComponentRef?.destroy();
  _rootComponentRef = null;
  debugClearComponentStyles();
}

void main() {
  // Start fetching the articles if we are a first time viewer.
  //
  // This will make the perceived first load faster, and allow us to avoid
  // a flash-of-unstyled-content (Loading...) for the initial load, which hurts
  // PWA scores.
  final prefetch = _prefetchFeed();

  installServiceWorker();

  // Start app after fetched.
  prefetch.then((_) {
    _rootComponentRef = runApp(
      app.AppComponentNgFactory,
      createInjector: hackerNewsApp,
    );
  });
}

/// Maybe prefetches data for the initial page if the source can be determined.
Future<void> _prefetchFeed() {
  final path = window.location.pathname;
  final query = window.location.search;
  // We don't bother prefetching a paginated feed or an item page, since it
  // avoids the need to parse parameters, and it's less likely a user will land
  // on such a view rather than a main feed.
  if (query.isNotEmpty || path.startsWith('/item')) return Future.value();
  // All feed route paths match the name of their corresponding feed, except for
  // the default route ('/') which corresponds to the 'news' feed.
  final feed = path == '/' ? 'news' : path.substring(1);
  return _service.getFeed(feed, 1);
}
