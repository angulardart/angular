library angular2.platform.testing.browser;

import "package:angular2/platform/testing/browser_static.dart"
    show
        TEST_BROWSER_STATIC_PLATFORM_PROVIDERS,
        ADDITIONAL_TEST_BROWSER_PROVIDERS;
import "package:angular2/platform/browser.dart" show BROWSER_APP_PROVIDERS;
/**
 * Providers for using template cache to avoid actual XHR.
 * Re-exported here so that tests import from a single place.
 */
export "package:angular2/platform/browser.dart" show CACHED_TEMPLATE_PROVIDER;

/**
 * Default platform providers for testing.
 */
const List<dynamic> TEST_BROWSER_PLATFORM_PROVIDERS = const [
  TEST_BROWSER_STATIC_PLATFORM_PROVIDERS
];
/**
 * Default application providers for testing.
 */
const List<dynamic> TEST_BROWSER_APPLICATION_PROVIDERS = const [
  BROWSER_APP_PROVIDERS,
  ADDITIONAL_TEST_BROWSER_PROVIDERS
];
