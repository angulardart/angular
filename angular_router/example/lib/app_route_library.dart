import 'package:angular_router/angular_router.dart';

final dashboard = new RoutePath(
  path: 'dashboard',
  useAsDefault: true,
);
final heroes = new RoutePath(
  path: 'heroes',
);
final detail = new RoutePath(
  path: 'detail/:id',
);
final admin = new RoutePath(
  path: 'admin',
);
final login = new RoutePath(
  path: 'login',
);

final adminDashboard = new RoutePath(
  parent: admin,
  path: 'dashboard',
  useAsDefault: true,
);
final adminHero = new RoutePath(
  parent: admin,
  path: 'heroes',
);
