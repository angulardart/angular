import 'package:angular/angular.dart';
import 'package:angular/experimental.dart';

import 'package:safe_html/safe_html.dart';

@Component(
  selector: 'comment',
  templateUrl: 'comment_component.html',
  styleUrls: ['comment_component.css'],
  directives: [
    CommentComponent,
    NgForIdentity,
    NgIf,
  ],
  changeDetection: ChangeDetectionStrategy.OnPush,
)
class CommentComponent {
  @Input()
  Map<String, dynamic> comment;

  bool hidden = false;

  SafeHtml get content => SafeHtml.sanitize(comment['content']);

  String get showCommentText => '+${comment['comments_count']}';

  void toggleVisibility() {
    hidden = !hidden;
  }
}
