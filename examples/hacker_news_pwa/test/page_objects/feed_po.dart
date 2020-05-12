import 'package:pageloader/pageloader.dart';

import 'item_po.dart';

part 'feed_po.g.dart';

@PageObject()
abstract class FeedPO {
  FeedPO();

  // ignore: redirect_to_non_class
  factory FeedPO.create(PageLoaderElement context) = $FeedPO.create;

  @ByTagName('item')
  List<ItemPO> get itemPOs;
}
