import '../core/testability/testability.dart';
import 'browser/testability.dart';

// Deprecated: But currently used naughtily by some internal clients.
export 'bootstrap.dart'
    show BROWSER_APP_PROVIDERS, BROWSER_APP_COMMON_PROVIDERS;

Function createInitDomAdapter(TestabilityRegistry testabilityRegistry) {
  return () {
    testabilityRegistry.setTestabilityGetter(new BrowserGetTestability());
  };
}
