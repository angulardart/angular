import 'package:angular/angular.dart';
import 'package:angular_router/angular_router.dart';

import 'routes.dart';

@Component(
  selector: 'item',
  templateUrl: 'item_component.html',
  styleUrls: const ['item_component.css'],
  directives: const [NgIf, routerDirectives],
  changeDetection: ChangeDetectionStrategy.OnPush,
)
class ItemComponent implements OnInit {
  @Input()
  Map item;

  String discuss;
  String discussUrl;
  String points;
  bool showDetail;

  @override
  ngOnInit() {
    final int numComments = item['comments_count'];
    discuss = numComments == 0
        ? 'discuss'
        // U+00A0 is a non-breaking space.
        : '$numComments\u00A0comment${numComments > 1 ? 's' : ''}';
    discussUrl = itemRoutePath.toUrl(parameters: {'id': '${item['id']}'});

    final int numPoints = item['points'];
    points = '$numPoints point${numPoints == 1 ? '' : 's'}';

    // Job items don't have an author, points, or discussion.
    showDetail = item['type'] != 'job';
  }
}
