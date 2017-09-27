import 'dart:async';

import 'package:angular/angular.dart';
import 'package:angular_router/angular_router.dart';

import 'app_route_library.dart' as routes;
import 'hero.dart';
import 'hero_service.dart';

@Component(
  selector: 'my-heroes',
  directives: const [NgFor, NgIf, RouterLink],
  templateUrl: 'heroes_component.html',
  styleUrls: const ['heroes_component.css'],
  // TODO(b/65383776): Change preserveWhitespace to false to improve codesize.
  preserveWhitespace: true,
)
class HeroesComponent implements OnInit {
  final HeroService _heroService;
  List<Hero> heroes;
  Hero selectedHero;

  HeroesComponent(this._heroService);

  Future<Null> getHeroes() async {
    heroes = await _heroService.getHeroes();
  }

  void ngOnInit() {
    getHeroes();
  }

  void onSelect(Hero hero) {
    selectedHero = hero;
  }

  String get heroUrl =>
      routes.detail.toUrl(parameters: {'id': selectedHero.id.toString()});
}
