import 'package:pageloader/pageloader.dart';

part 'item_po.g.dart';

@PageObject()
abstract class ItemPO {
  ItemPO();

  factory ItemPO.create(PageLoaderElement context) = $ItemPO.create;

  @ByTagName('a')
  List<PageLoaderElement> get _links;

  @ByCss('.secondary')
  PageLoaderElement get _secondary;

  PageLoaderElement get contentLink => _links[0];

  PageLoaderElement get discussionLink => _links[1];

  String get subtitle => _secondary.visibleText;

  String get title => contentLink.visibleText;
}
