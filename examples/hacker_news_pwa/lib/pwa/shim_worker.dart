import 'package:pwa/worker.dart';

import 'package:examples.hacker_news_pwa/hacker_news_service.dart';
import 'package:examples.hacker_news_pwa/pwa/offline_urls.g.dart' as offline;

void setupWorkerCache() {
  final cache = DynamicCache('hacker-news-service');
  Worker()
    ..offlineUrls = offline.offlineUrls
    ..router.registerGetUrl(defaultBaseUrl, cache.networkFirst)
    ..run(version: offline.lastModified);
}
