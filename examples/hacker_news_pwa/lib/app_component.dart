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
  styleUrls: const ['app_component.css'],
  directives: const [routerDirectives],
)
class AppComponent {
  final newsUrl = newsRoutePath.toUrl();
  final newUrl = newRoutePath.toUrl();
  final showUrl = showRoutePath.toUrl();
  final askUrl = askRoutePath.toUrl();
  final jobsUrl = jobsRoutePath.toUrl();
  final routes = [
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
