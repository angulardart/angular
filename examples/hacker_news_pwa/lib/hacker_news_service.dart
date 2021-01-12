import 'dart:convert';
import 'dart:html';

import 'package:angular/angular.dart';

/// Represents the base URL for HTTP requests using [HackerNewsService].
const baseUrl = OpaqueToken<String>('baseUrl');

const defaultBaseUrl = 'https://api.hnpwa.com/v0';

class HackerNewsService {
  final String _baseUrl;

  // Store the last feed in memory to instantly load when requested.
  String? _cacheFeedKey;
  List<Map<String, Object?>>? _cacheFeedResult;

  HackerNewsService(@baseUrl this._baseUrl);

  Future<List<Map<String, Object?>>> getFeed(String name, int page) {
    final url = '$_baseUrl/$name/$page.json';
    if (_cacheFeedKey == url) {
      return Future.value(_cacheFeedResult);
    }
    return HttpRequest.getString(url).then((response) {
      final decoded = json.decode(response) as List<Object?>;
      _cacheFeedKey = url;
      return _cacheFeedResult = List.from(decoded);
    });
  }

  Future<Map<String, Object?>> getItem(String id) {
    final url = '$_baseUrl/item/$id.json';
    return HttpRequest.getString(url).then((response) {
      return json.decode(response) as Map<String, Object?>;
    });
  }
}
