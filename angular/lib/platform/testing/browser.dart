library angular.platform.testing.browser;

import 'package:angular/src/platform/bootstrap.dart';

import 'browser_static.dart'
    show
        TEST_BROWSER_STATIC_PLATFORM_PROVIDERS,
        ADDITIONAL_TEST_BROWSER_PROVIDERS;

export 'package:angular/src/debug/debug_node.dart'
    show inspectNativeElement, DebugNode, DebugElement, By;

/// Default platform providers for testing.
const List<dynamic> TEST_BROWSER_PLATFORM_PROVIDERS = const [
  TEST_BROWSER_STATIC_PLATFORM_PROVIDERS
];

/// Default application providers for testing.
const List<dynamic> TEST_BROWSER_APPLICATION_PROVIDERS = const [
  BROWSER_APP_PROVIDERS,
  ADDITIONAL_TEST_BROWSER_PROVIDERS
];
