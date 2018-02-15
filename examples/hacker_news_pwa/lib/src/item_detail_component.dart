import 'dart:async';

import 'package:angular/angular.dart';
import 'package:angular_router/angular_router.dart';

import '../hacker_news_service.dart';
import 'comment_component.dart';
import 'item_component.dart';

/// Recursively populates comment count for all comments.
///
/// The number of replies to a comment, including the comment itself, are stored
/// in 'comments_count' for each comment.
int countComments(Map comment) =>
    comment['comments_count'] = comment['comments'].fold(
        1, (int numReplies, Map reply) => numReplies + countComments(reply));

@Component(
  selector: 'item-detail',
  templateUrl: 'item_detail_component.html',
  styleUrls: const ['item_detail_component.css'],
  directives: const [CommentComponent, ItemComponent, NgFor, NgIf],
)
class ItemDetailComponent implements OnActivate {
  final HackerNewsService _hackerNewsService;

  Map item;

  ItemDetailComponent(this._hackerNewsService);

  @override
  Future onActivate(_, RouterState current) async {
    final id = current.parameters['id'];
    item = await _hackerNewsService.getItem(id)
      ..['comments'].forEach(countComments);
  }
}
