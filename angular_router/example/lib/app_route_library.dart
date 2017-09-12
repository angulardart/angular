import 'package:angular_router/angular_router.dart';

final dashboard = new RouteLibrary(
  path: 'dashboard',
  useAsDefault: true,
);
final heroes = new RouteLibrary(
  path: 'heroes',
);
final detail = new RouteLibrary(
  path: 'detail/:id',
);
final admin = new RouteLibrary(
  path: 'admin',
);
final login = new RouteLibrary(
  path: 'login',
);

final adminDashboard = new RouteLibrary(
  path: 'dashboard',
  useAsDefault: true,
);
final adminHero = new RouteLibrary(
  path: 'heroes',
);
