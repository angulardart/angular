// ignore_for_file: uri_has_not_been_generated
import 'package:angular/angular.dart';
import 'package:angular_router/angular_router.dart';

import 'admin/admin_component.template.dart' deferred as admin_lib;
import 'app_route_library.dart' as app_routes;
import 'auth_service.dart';
import 'dashboard_component.template.dart' as dashboard_component;
import 'hero_detail_component.template.dart' as hero_detail_component;
import 'hero_service.dart';
import 'heroes_component.template.dart' as heroes_component;
import 'login_component.template.dart' as login_component;

@Component(
  selector: 'my-app',
  directives: const [routerDirectives],
  providers: const [AuthService, HeroService],
  template: '''
      <h1>{{title}}</h1>
      <nav>
        <a [routerLink]="dashboardRoute" routerLinkActive="router-link-active">Dashboard</a>
        <a [routerLink]="heroesRoute" routerLinkActive="router-link-active">Heroes</a>
        <a [routerLink]="adminRoute" routerLinkActive="router-link-active">Admin</a>
        <a [routerLink]="loginRoute" routerLinkActive="router-link-active">Login</a>
      </nav>
      <router-outlet [routes]="routes"></router-outlet>
    ''',
  styleUrls: const ['app_component.css'],
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class AppComponent {
  String adminRoute = app_routes.admin.toUrl();
  String dashboardRoute = app_routes.dashboard.toUrl();
  String heroesRoute = app_routes.heroes.toUrl();
  String loginRoute = app_routes.login.toUrl();
  String title = 'Tour of Heroes';
  final List<RouteDefinition> routes = [
    new RouteDefinition(
      routePath: app_routes.dashboard,
      component: dashboard_component.DashboardComponentNgFactory,
    ),
    new RouteDefinition(
      routePath: app_routes.heroes,
      component: heroes_component.HeroesComponentNgFactory,
    ),
    new RouteDefinition(
      routePath: app_routes.detail,
      component: hero_detail_component.HeroDetailComponentNgFactory,
    ),
    new RouteDefinition.defer(
      routePath: app_routes.admin,
      loader: () async {
        await admin_lib.loadLibrary();
        admin_lib.initReflector();
        return admin_lib.AdminComponentNgFactory;
      },
    ),
    new RouteDefinition(
      routePath: app_routes.login,
      component: login_component.LoginComponentNgFactory,
    ),
  ];
}
