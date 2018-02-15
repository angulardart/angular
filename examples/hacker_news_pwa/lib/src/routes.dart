import 'package:angular_router/angular_router.dart';

final newsRoutePath = new RoutePath(
  path: '/',
  additionalData: const {'feed': 'news'},
  useAsDefault: true,
);

final newRoutePath = new RoutePath(
  path: '/new',
  additionalData: const {'feed': 'newest'},
);

final showRoutePath = new RoutePath(
  path: '/show',
  additionalData: const {'feed': 'show'},
);

final askRoutePath = new RoutePath(
  path: '/ask',
  additionalData: const {'feed': 'ask'},
);

final jobsRoutePath = new RoutePath(
  path: '/jobs',
  additionalData: const {'feed': 'jobs'},
);

final itemRoutePath = new RoutePath(path: '/item/:id');
