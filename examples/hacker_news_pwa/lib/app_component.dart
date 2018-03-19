// Ignore generated templates imported for route definitions.
// ignore_for_file: uri_has_not_been_generated

import 'package:angular/angular.dart';
import 'package:angular_router/angular_router.dart';

import 'src/feed_component.template.dart' as feed;
import 'src/item_detail_component.template.dart' deferred as item_detail;
import 'src/routes.dart';

@Component(
  selector: 'app',
  templateUrl: 'app_component.html',
  directives: const [routerDirectives],
  // Disabled. We use global styles that are used before the JavaScript loads.
  //
  // See web/index.html's <style> tag.
  encapsulation: ViewEncapsulation.None,
)
class AppComponent {
  static final newsUrl = newsRoutePath.toUrl();
  static final newUrl = newRoutePath.toUrl();
  static final showUrl = showRoutePath.toUrl();
  static final askUrl = askRoutePath.toUrl();
  static final jobsUrl = jobsRoutePath.toUrl();

  static final routes = [
    new RouteDefinition(
      routePath: newsRoutePath,
      component: feed.FeedComponentNgFactory,
    ),
    new RouteDefinition(
      routePath: newRoutePath,
      component: feed.FeedComponentNgFactory,
    ),
    new RouteDefinition(
      routePath: showRoutePath,
      component: feed.FeedComponentNgFactory,
    ),
    new RouteDefinition(
      routePath: askRoutePath,
      component: feed.FeedComponentNgFactory,
    ),
    new RouteDefinition(
      routePath: jobsRoutePath,
      component: feed.FeedComponentNgFactory,
    ),
    new RouteDefinition.defer(
      routePath: itemRoutePath,
      loader: () async {
        await item_detail.loadLibrary();
        return item_detail.ItemDetailComponentNgFactory;
      },
    ),
  ];
}
