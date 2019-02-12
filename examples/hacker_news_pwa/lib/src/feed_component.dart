import 'package:angular/angular.dart';
import 'package:angular/experimental.dart';
import 'package:angular_router/angular_router.dart';

import '../hacker_news_service.dart';
import 'item_component.dart';

const itemsPerPage = 30;

@Component(
  selector: 'feed',
  templateUrl: 'feed_component.html',
  styleUrls: ['feed_component.css'],
  directives: [
    ItemComponent,
    NgForIdentity,
    NgIf,
    routerDirectives,
  ],
  encapsulation: ViewEncapsulation.None,
)
class FeedComponent implements OnActivate {
  final HackerNewsService _hackerNewsService;

  List<Map> items;
  String nextPageUrl;
  String previousPageUrl;
  int startingRank;

  FeedComponent(this._hackerNewsService);

  @override
  void onActivate(_, RouterState current) {
    final routePath = current.routePath;
    final String feed = routePath.additionalData['feed'];
    final page = current.queryParameters['p'];
    final pageNumber = page != null ? int.tryParse(page) ?? 1 : 1;

    if (pageNumber < 10) {
      nextPageUrl =
          routePath.toUrl(queryParameters: {'p': '${pageNumber + 1}'});
    }

    if (pageNumber > 1) {
      previousPageUrl =
          routePath.toUrl(queryParameters: {'p': '${pageNumber - 1}'});
    }

    startingRank = itemsPerPage * (pageNumber - 1) + 1;
    _hackerNewsService.getFeed(feed, pageNumber).then((result) {
      items = result;
    });
  }
}
