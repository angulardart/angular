// ignore_for_file: uri_has_not_been_generated
import 'dart:async';

import 'package:angular/angular.dart';
import 'package:angular_router/angular_router.dart';

import '../app_route_library.dart' as app_routes;
import '../auth_service.dart';
import 'admin_dashboard_component.template.dart' as admin_dashboard_component;
import 'admin_heroes_component.template.dart' as admin_heroes_component;

@Component(
  selector: 'admin',
  directives: const [routerDirectives],
  template: '''
      <h3>ADMIN</h3>
      <nav>
        <a routerLink="adminDashboardRoute">Dashboard</a>
        <a routerLink="adminHeroRoute">Manage Heroes</a>
      </nav>
      <router-outlet [routes]="routes"></router-outlet>
    ''',
  // TODO(b/65383776): Change preserveWhitespace to false to improve codesize.
  preserveWhitespace: true,
)
class AdminComponent implements CanActivate {
  String adminDashboardRoute = app_routes.adminDashboard.toUrl();
  String adminHeroRoute = app_routes.adminHero.toUrl();
  final List<RouteDefinition> routes = [
    new RouteDefinition(
      routePath: app_routes.adminDashboard,
      component: admin_dashboard_component.AdminDashboardComponentNgFactory,
    ),
    new RouteDefinition(
      routePath: app_routes.adminHero,
      component: admin_heroes_component.AdminHeroesComponentNgFactory,
    ),
    new RouteDefinition.redirect(path: '/.*', redirectTo: './dashboard'),
  ];

  final AuthService _authService;
  final Router _router;

  AdminComponent(this._authService, this._router);

  @override
  Future<bool> canActivate(_, RouterState nextState) async {
    if (_authService.isLoggedIn) {
      return true;
    }

    // If not logged in, redirect to /login with sessionId/fragment
    _authService.redirectUrl = nextState.path;
    await _router.navigate(
        '/login',
        new NavigationParams(
            queryParameters: {'sessionId': 'abcd'}, fragment: 'anchor'));
    return false;
  }
}
