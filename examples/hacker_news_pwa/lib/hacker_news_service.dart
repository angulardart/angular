import 'dart:async';
import 'dart:convert';

import 'package:angular/angular.dart';
import 'package:http/http.dart';

/// Represents the base URL for HTTP requests using [HackerNewsService].
const baseUrl = const OpaqueToken<String>('baseUrl');
const defaultBaseUrl = 'https://node-hnapi.herokuapp.com';

class HackerNewsService {
  final String _baseUrl;
  final BaseClient _client;

  // Store the last feed in memory to instantly load when requested.
  String _cacheFeedKey;
  List<Map> _cacheFeedResult;

  HackerNewsService(@baseUrl this._baseUrl, this._client);

  Future<List<Map>> getFeed(String name, int page) async {
    final url = '$_baseUrl/$name?page=$page';
    if (_cacheFeedKey == url) {
      return _cacheFeedResult;
    }
    final response = await _client.get(url);
    final decoded = JSON.decode(response.body) as List;
    _cacheFeedKey = url;
    return _cacheFeedResult = decoded.cast<Map>();
  }

  Future<Map> getItem(String id) async {
    final url = '$_baseUrl/item/$id';
    final response = await _client.get(url);
    return JSON.decode(response.body);
  }
}
