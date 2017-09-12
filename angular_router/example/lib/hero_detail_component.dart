import 'dart:async';
import 'dart:html';

import 'package:angular/angular.dart';
import 'package:angular_forms/angular_forms.dart';
import 'package:angular_router/angular_router.dart';

import 'hero.dart';
import 'hero_service.dart';

@Component(
    selector: 'my-hero-detail',
    directives: const [NgIf, formDirectives],
    templateUrl: 'hero_detail_component.html',
    styleUrls: const ['hero_detail_component.css'])
class HeroDetailComponent implements CanDeactivate, OnActivate {
  final HeroService _heroService;
  final Window _window;
  Hero hero;
  String editName;

  HeroDetailComponent(this._heroService, this._window);

  @override
  void onActivate(_, RouterState newState) {
    updateHero(newState);
  }

  @override
  Future<bool> canDeactivate(_, __) async {
    if (hero.name == editName) {
      return true;
    }

    return _window.confirm('Discard changes?');
  }

  Future<Null> updateHero(RouterState newState) async {
    var idString = newState.parameters['id'];
    var id = int.parse(idString ?? '', onError: (_) => null);
    if (id != null) {
      hero = await (_heroService.getHero(id));
      editName = hero.name;
    }
  }

  void save() {
    hero.name = editName;
  }

  void goBack() {
    window.history.back();
  }
}
