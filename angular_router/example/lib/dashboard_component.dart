import 'dart:async';

import 'package:angular/angular.dart';
import 'package:angular_router/angular_router.dart';

import 'app_route_library.dart' as app_routes;
import 'hero.dart';
import 'hero_service.dart';

@Component(
  selector: 'my-dashboard',
  directives: const [NgFor, RouterLink],
  templateUrl: 'dashboard_component.html',
  styleUrls: const ['dashboard_component.css'],
  // TODO(b/65383776): Change preserveWhitespace to false to improve codesize.
  preserveWhitespace: true,
)
class DashboardComponent implements OnInit {
  List<Hero> heroes;

  final HeroService _heroService;

  DashboardComponent(this._heroService);

  Future<Null> ngOnInit() async {
    heroes = (await _heroService.getHeroes()).skip(1).take(4).toList();
  }

  String heroUrl(Hero hero) =>
      app_routes.detail.toUrl(parameters: {'id': hero.id.toString()});
}
