import 'dart:async';
import 'dart:convert';
import 'dart:html';

import 'package:angular/angular.dart';

/// Represents the base URL for HTTP requests using [HackerNewsService].
const baseUrl = const OpaqueToken<String>('baseUrl');

const defaultBaseUrl = 'https://api.hnpwa.com/v0';

class HackerNewsService {
  final String _baseUrl;

  // Store the last feed in memory to instantly load when requested.
  String _cacheFeedKey;
  List<Map> _cacheFeedResult;

  HackerNewsService(@baseUrl this._baseUrl);

  Future<List<Map>> getFeed(String name, int page) {
    final url = '$_baseUrl/$name/$page.json';
    if (_cacheFeedKey == url) {
      return new Future.value(_cacheFeedResult);
    }
    return HttpRequest.getString(url).then((response) {
      final List<dynamic> decoded = JSON.decode(response);
      _cacheFeedKey = url;
      return _cacheFeedResult = new List<Map>.from(decoded);
    });
  }

  Future<Map> getItem(String id) {
    final url = '$_baseUrl/item/$id.json';
    return HttpRequest.getString(url).then((response) {
      final Map decoded = JSON.decode(response);
      return decoded;
    });
  }
}
