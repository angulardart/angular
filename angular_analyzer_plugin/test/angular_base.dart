import 'analyzer_base.dart';
import 'mock_angular.dart';

class AngularTestBase extends AnalyzerTestBase {
  @override
  void setUp() {
    super.setUp();
    addAngularSources(newSource);
  }
}
