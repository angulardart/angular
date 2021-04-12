import '../link.dart';

const _globalSingletonServices = [
  TypeLink(
    'ApplicationRef',
    'asset:angular/lib/src/core/application_ref.dart',
  ),
  TypeLink(
    'AppViewUtils',
    'asset:angular/lib/src/core/linker/app_view_utils.dart',
  ),
  TypeLink(
    'NgZone',
    'asset:angular/lib/src/core/zone/ng_zone.dart',
  ),
  TypeLink(
    'Testability',
    'asset:angular/lib/src/testability/implementation.dart',
  ),
];

bool isGlobalSingletonService(TypeLink service) =>
    _globalSingletonServices.contains(service);
