import 'package:safe_html/safe_html.dart';
import 'package:angular/angular.dart';
import 'package:angular/experimental.dart';

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
  late Map<String, Object?> comment;

  bool hidden = false;

  SafeHtml get content => SafeHtml.sanitize(comment['content'] as String);

  String get showCommentText => '+${comment['comments_count']}';

  void toggleVisibility() {
    hidden = !hidden;
  }

  // TODO(b/171232371): Use `as` in the template instead?
  Iterable<Object?> readCommentsAsIterable() =>
      comment['comments'] as Iterable<Object?>;
}
