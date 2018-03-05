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

  HackerNewsService(this._baseUrl, this._client);

  Future<List<Map>> getFeed(String name, int page) async {
    final url = '$_baseUrl/$name?page=$page';
    final response = await _client.get(url);
    return JSON.decode(response.body);
  }

  Future<Map> getItem(String id) async {
    final url = '$_baseUrl/item/$id';
    final response = await _client.get(url);
    return JSON.decode(response.body);
  }
}
