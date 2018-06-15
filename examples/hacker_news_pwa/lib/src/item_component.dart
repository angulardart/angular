import 'package:angular/angular.dart';
import 'package:angular_router/angular_router.dart';

import 'routes.dart';

@Component(
  selector: 'item',
  templateUrl: 'item_component.html',
  styleUrls: ['item_component.css'],
  directives: [NgIf, RouterLink],
  changeDetection: ChangeDetectionStrategy.OnPush,
)
class ItemComponent {
  Map _item;

  String discuss;
  String discussUrl;
  String points;
  bool linkDiscussion;
  bool showDetail;

  Map get item => _item;

  @Input()
  set item(Map value) {
    final int numComments = value['comments_count'];
    discuss = numComments == 0
        ? 'discuss'
        // U+00A0 is a non-breaking space.
        : '$numComments\u00A0comment${numComments > 1 ? 's' : ''}';
    discussUrl = itemRoutePath.toUrl(parameters: {'id': '${value['id']}'});

    final int numPoints = value['points'];
    points = '$numPoints point${numPoints == 1 ? '' : 's'}';

    // Ask items link directly to their discussion. Oddly, not all items in the
    // ask feed have the 'ask' type, so it's safest to just check the URL. When
    // we see a relative item URL, we use the router link to its discussion
    // instead.
    final String url = value['url'];
    linkDiscussion = url.startsWith('item');

    // Job items don't have an author, points, or discussion.
    showDetail = value['type'] != 'job';

    _item = value;
  }
}
