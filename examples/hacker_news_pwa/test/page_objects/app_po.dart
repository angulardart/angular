import 'package:pageloader/pageloader.dart';

import 'feed_po.dart';
import 'item_detail_po.dart';

part 'app_po.g.dart';

@PageObject()
abstract class AppPO {
  AppPO();

  factory AppPO.create(PageLoaderElement context) = $AppPO.create;

  @ByTagName('feed')
  FeedPO get feedPO;

  @ByTagName('item-detail')
  ItemDetailPO get itemDetailPO;
}
