import 'package:pwa/worker.dart';

import 'package:examples.hacker_news_pwa/hacker_news_service.dart';
import 'package:examples.hacker_news_pwa/pwa/offline_urls.g.dart' as offline;

void main() {
  final cache = new DynamicCache('hacker-news-service');
  new Worker()
    ..offlineUrls = offline.offlineUrls
    ..router.registerGetUrl(HackerNewsService.baseUrl, cache.networkFirst)
    ..run(version: offline.lastModified);
}
