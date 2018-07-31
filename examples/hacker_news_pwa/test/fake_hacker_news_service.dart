import 'dart:async';

import 'package:examples.hacker_news_pwa/hacker_news_service.dart';

List<Map> _createFeed(int numItems) => List.generate(numItems, _createItem);

Map _createItem(int id, {bool withComments = false}) {
  final item = {
    'comments_count': id,
    'id': id,
    'points': id,
    'user': 'User $id',
    'time_ago': '$id minutes ago',
    'title': 'Title $id',
    'type': 'link',
    'url': 'Url $id',
  };
  if (withComments) {
    item['comments'] = List.generate(id, (i) {
      return {
        'comments': [],
        'content': 'Comment $i',
      };
    });
  }
  return item;
}

class FakeHackerNewsService implements HackerNewsService {
  const FakeHackerNewsService();

  @override
  Future<List<Map>> getFeed(_, __) => Future.value(_createFeed(30));

  @override
  Future<Map> getItem(String id) =>
      Future.value(_createItem(int.parse(id), withComments: true));
}
