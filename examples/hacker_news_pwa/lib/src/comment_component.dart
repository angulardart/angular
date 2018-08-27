import 'package:angular/angular.dart';
import 'package:angular/experimental.dart';
import 'package:angular/security.dart';

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
  final DomSanitizationService _sanitizer;

  @Input()
  Map comment;

  bool hidden = false;

  CommentComponent(this._sanitizer);

  SafeHtml get content =>
      _sanitizer.bypassSecurityTrustHtml(comment['content']);

  String get showCommentText => '+${comment['comments_count']}';

  void toggleVisibility() {
    hidden = !hidden;
  }
}
