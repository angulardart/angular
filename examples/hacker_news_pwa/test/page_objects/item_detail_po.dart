import 'package:pageloader/pageloader.dart';

import 'comment_po.dart';
import 'item_po.dart';

part 'item_detail_po.g.dart';

@PageObject()
abstract class ItemDetailPO {
  ItemDetailPO();

  factory ItemDetailPO.create(PageLoaderElement context) = $ItemDetailPO.create;

  @ByTagName('item')
  ItemPO get itemPO;

  // This prevents selecting recursively nested comments.
  @ByCss('item-detail > comment')
  List<CommentPO> get commentPOs;
}
