import 'dart:async';
import 'dart:convert';
import 'dart:html';

import 'package:angular/angular.dart';

/// A default implementation of the GitHub API using `dart:html`.
@Injectable()
class GithubService {
  static const String _apiEndpoint = 'https://api.github.com';
  static const String _repoEndpoint = '$_apiEndpoint/repos/dart-lang/angular';
  static const String _allIssuesEndpoint = '$_repoEndpoint/issues?filter=all';

  Stream<GithubIssue> getIssues() async* {
    final payload = await HttpRequest.getString(_allIssuesEndpoint);
    final issues = (json.decode(payload) as List).cast<Map<String, dynamic>>();
    for (final issue in issues) {
      yield GithubIssue.parse(issue);
    }
  }
}

/// A typed API over the JSON blob from Github representing an issue.
///
/// See: https://developer.github.com/v3/issues/.
class GithubIssue {
  /// ID of the issue.
  final int id;

  /// URL of the issue.
  final Uri url;

  /// Title of the issue.
  final String title;

  /// Author of the issue.
  final String author;

  /// Description of the issue.
  final String description;

  const GithubIssue({
    this.id,
    this.url,
    this.title,
    this.author,
    this.description,
  });

  factory GithubIssue.parse(Map<String, dynamic> json) {
    return GithubIssue(
      id: json['id'],
      url: Uri.parse(json['html_url']),
      title: json['title'],
      author: json['user']['login'],
      description: json['body'],
    );
  }
}
