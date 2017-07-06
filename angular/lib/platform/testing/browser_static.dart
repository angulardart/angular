library angular.platform.testing.browser_static;

import 'dart:html';

import 'package:angular/core.dart'
    show APP_ID, Provider, PLATFORM_COMMON_PROVIDERS, PLATFORM_INITIALIZER;
import 'package:angular/platform/common.dart' show LocationStrategy;
import 'package:angular/src/core/linker/app_view_utils.dart' show AppViewUtils;
import 'package:angular/src/mock/mock_location_strategy.dart'
    show MockLocationStrategy;
import 'package:angular/src/platform/browser_common.dart'
    show BROWSER_APP_COMMON_PROVIDERS;
import 'package:angular/src/platform/dom/dom_tokens.dart' show DOCUMENT;
import 'package:angular/src/testing/test_component_builder.dart'
    show TestComponentBuilder;
import 'package:angular/src/testing/utils.dart' show BrowserDetection, Log;

void initBrowserTests() {
  BrowserDetection.setup();
}

/// Default platform providers for testing without a compiler.
const List<dynamic> TEST_BROWSER_STATIC_PLATFORM_PROVIDERS = const [
  PLATFORM_COMMON_PROVIDERS,
  const Provider(PLATFORM_INITIALIZER, useValue: initBrowserTests, multi: true)
];
const List<dynamic> ADDITIONAL_TEST_BROWSER_PROVIDERS = const [
  const Provider(APP_ID, useValue: 'a'),
  AppViewUtils,
  Log,
  TestComponentBuilder,
  const Provider(LocationStrategy, useClass: MockLocationStrategy),
];

/// Default application providers for testing without a compiler.
const List<dynamic> TEST_BROWSER_STATIC_APPLICATION_PROVIDERS = const [
  BROWSER_APP_COMMON_PROVIDERS,
  ADDITIONAL_TEST_BROWSER_PROVIDERS,
  const Provider(DOCUMENT, useFactory: createDoc, deps: const []),
];

createDoc() => document;
