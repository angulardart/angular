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
  directives: [routerDirectives],
  styleUrls: ['app_component.css'],
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
    RouteDefinition(
      routePath: newsRoutePath,
      component: feed.FeedComponentNgFactory,
    ),
    RouteDefinition(
      routePath: newRoutePath,
      component: feed.FeedComponentNgFactory,
    ),
    RouteDefinition(
      routePath: showRoutePath,
      component: feed.FeedComponentNgFactory,
    ),
    RouteDefinition(
      routePath: askRoutePath,
      component: feed.FeedComponentNgFactory,
    ),
    RouteDefinition(
      routePath: jobsRoutePath,
      component: feed.FeedComponentNgFactory,
    ),
    RouteDefinition.defer(
      routePath: itemRoutePath,
      loader: () {
        return item_detail.loadLibrary().then((_) {
          return item_detail.ItemDetailComponentNgFactory;
        });
      },
    ),
  ];
}
