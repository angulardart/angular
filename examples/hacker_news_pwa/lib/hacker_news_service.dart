import 'dart:async';
import 'dart:convert';
import 'dart:html';

import 'package:angular/angular.dart';

/// Represents the base URL for HTTP requests using [HackerNewsService].
const baseUrl = const OpaqueToken<String>('baseUrl');
const defaultBaseUrl = 'https://node-hnapi.herokuapp.com';

class HackerNewsService {
  final String _baseUrl;

  HackerNewsService(@baseUrl this._baseUrl);

  Future<List<Map>> getFeed(String name, int page) async {
    final url = '$_baseUrl/$name?page=$page';
    final response = await HttpRequest.getString(url);
    return JSON.decode(response);
  }

  Future<Map> getItem(String id) async {
    final url = '$_baseUrl/item/$id';
    final response = await HttpRequest.getString(url);
    return JSON.decode(response);
  }
}
