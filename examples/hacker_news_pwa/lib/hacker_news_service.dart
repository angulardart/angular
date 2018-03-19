import 'dart:async';
import 'dart:convert';
import 'dart:html';

import 'package:angular/angular.dart';

/// Represents the base URL for HTTP requests using [HackerNewsService].
const baseUrl = const OpaqueToken<String>('baseUrl');
const defaultBaseUrl = 'https://node-hnapi.herokuapp.com';

class HackerNewsService {
  final String _baseUrl;

  // Store the last feed in memory to instantly load when requested.
  String _cacheFeedKey;
  List<Map> _cacheFeedResult;

  HackerNewsService(@baseUrl this._baseUrl);

  Future<List<Map>> getFeed(String name, int page) async {
    final url = '$_baseUrl/$name?page=$page';
    if (_cacheFeedKey == url) {
      return _cacheFeedResult;
    }
    final response = await HttpRequest.getString(url);
    final decoded = JSON.decode(response) as List;
    _cacheFeedKey = url;
    return _cacheFeedResult = decoded.cast<Map>();
  }

  Future<Map> getItem(String id) async {
    final url = '$_baseUrl/item/$id';
    final response = await HttpRequest.getString(url);
    return JSON.decode(response);
  }
}
