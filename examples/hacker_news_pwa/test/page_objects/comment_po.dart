import 'package:pageloader/pageloader.dart';

part 'comment_po.g.dart';

@PageObject()
abstract class CommentPO {
  CommentPO();

  factory CommentPO.create(PageLoaderElement context) = $CommentPO.create;

  @ByCss('.content')
  PageLoaderElement get _content;

  String get text => _content.visibleText;
}
