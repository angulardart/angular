import '../core/testability/testability.dart';
import 'browser/testability.dart';

Function createInitDomAdapter(TestabilityRegistry testabilityRegistry) {
  return () {
    testabilityRegistry.setTestabilityGetter(new BrowserGetTestability());
  };
}
