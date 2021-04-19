import 'package:pageloader3/pageloader.dart';

part 'comment_po.g.dart';

@PageObject()
abstract class CommentPO {
  CommentPO();

  // ignore: redirect_to_non_class
  factory CommentPO.create(PageLoaderElement context) = $CommentPO.create;

  @ByCss('.content')
  PageLoaderElement get _content;

  String get text => _content.visibleText;
}
