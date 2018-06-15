import 'package:angular_router/angular_router.dart';

final newsRoutePath = RoutePath(
  path: '/',
  additionalData: const {'feed': 'news'},
  useAsDefault: true,
);

final newRoutePath = RoutePath(
  path: '/newest',
  additionalData: const {'feed': 'newest'},
);

final showRoutePath = RoutePath(
  path: '/show',
  additionalData: const {'feed': 'show'},
);

final askRoutePath = RoutePath(
  path: '/ask',
  additionalData: const {'feed': 'ask'},
);

final jobsRoutePath = RoutePath(
  path: '/jobs',
  additionalData: const {'feed': 'jobs'},
);

final itemRoutePath = RoutePath(path: '/item/:id');
