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
  Map<String, Object?>? _item;

  // TODO(b/171232036): Determine if this should be nullable or not.
  String discussUrl = '';

  String? discuss;
  String? points;
  var linkDiscussion = false;
  var showDetail = false;

  Map<String, Object?> get item => _item!;

  @Input()
  set item(Map<String, Object?> value) {
    final numComments = value['comments_count'] as int;
    discuss = numComments == 0
        ? 'discuss'
        // U+00A0 is a non-breaking space.
        : '$numComments\u00A0comment${numComments > 1 ? 's' : ''}';
    discussUrl = itemRoutePath.toUrl(parameters: {'id': '${value['id']}'});

    final numPoints = value['points'] as int;
    points = '$numPoints point${numPoints == 1 ? '' : 's'}';

    // Ask items link directly to their discussion. Oddly, not all items in the
    // ask feed have the 'ask' type, so it's safest to just check the URL. When
    // we see a relative item URL, we use the router link to its discussion
    // instead.
    final url = value['url'] as String;
    linkDiscussion = url.startsWith('item');

    // Job items don't have an author, points, or discussion.
    showDetail = value['type'] != 'job';

    _item = value;
  }
}
