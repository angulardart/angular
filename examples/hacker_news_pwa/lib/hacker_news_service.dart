import 'dart:async';
import 'dart:convert';

import 'package:http/browser_client.dart';

class HackerNewsService {
  static const String baseUrl = 'https://node-hnapi.herokuapp.com';
  final BrowserClient _client;

  HackerNewsService() : _client = new BrowserClient();

  Future<List<Map>> getFeed(String name, int page) async {
    final url = '$baseUrl/$name?page=$page';
    final response = await _client.get(url);
    return JSON.decode(response.body);
  }

  Future<Map> getItem(String id) async {
    final url = '$baseUrl/item/$id';
    final response = await _client.get(url);
    return JSON.decode(response.body);
  }
}
