import 'dart:async';

import 'package:angular/angular.dart';
import 'package:angular_router/angular_router.dart';

import '../hacker_news_service.dart';
import 'item_component.dart';

const itemsPerPage = 30;

@Component(
  selector: 'feed',
  templateUrl: 'feed_component.html',
  styleUrls: const ['feed_component.css'],
  directives: const [ItemComponent, NgFor, NgIf, routerDirectives],
)
class FeedComponent implements OnActivate {
  final HackerNewsService _hackerNewsService;

  List<Map> items;
  String nextPageUrl;
  int startingRank;

  FeedComponent(this._hackerNewsService);

  @override
  Future onActivate(_, RouterState current) async {
    final routePath = current.routePath;
    final String feed = routePath.additionalData['feed'];
    final page = current.queryParameters['p'];
    final pageNumber = page != null ? int.parse(page, onError: (_) => 1) : 1;
    nextPageUrl = routePath.toUrl(queryParameters: {'p': '${pageNumber + 1}'});
    startingRank = itemsPerPage * (pageNumber - 1) + 1;
    items = await _hackerNewsService.getFeed(feed, pageNumber);
  }
}
