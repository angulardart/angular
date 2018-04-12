import '../core/testability/testability.dart';
import 'browser/testability.dart';

void initTestability(TestabilityRegistry testabilityRegistry) {
  testabilityRegistry.setTestabilityGetter(new BrowserGetTestability());
}
