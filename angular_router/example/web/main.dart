import 'dart:html';

import 'package:angular/angular.dart';
import 'package:angular_router/angular_router.dart';
import 'package:angular_router.example/app_component.dart';

import 'main.template.dart' as ng;
// Automatically generated at compile-time.
// ignore: uri_has_not_been_generated

void main() {
  bootstrapStatic(
    AppComponent,
    [
      routerProviders,
      // We use this instead of <base href="/" /> to make local development
      // nicer (i.e. load "styles.css" relatively).
      const Provider(APP_BASE_HREF, useValue: '/'),
      new Provider(Window, useValue: window),
    ],
    ng.initReflector,
  );
}
