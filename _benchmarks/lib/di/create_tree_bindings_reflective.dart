import 'package:angular/angular.dart';

import '../common.dart';
import 'src/tree_bindings.dart';

/// Initializes and injects a tree of DI services typical to a small web app.
///
/// Set [ready] to true to create the tree.
@Component(
  selector: 'create-20-bindings-benchmark',
  directives: [
    NgIf,
  ],
  template: r'',
)
class CreateTreeBindingsReflectiveBenchmark implements Benchmark {
  @override
  void start() => ready = true;

  @override
  void reset() => ready = false;

  set ready(bool ready) {
    if (ready) {
      runBenchmark();
    }
  }

  static void runBenchmark() {
    final app = ReflectiveInjector.resolveAndCreate(simpleTreeAppBindings);
    for (var i = 0; i < numberOfPages; i++) {
      final page = ReflectiveInjector.resolveAndCreate(
        simpleTreePageBindings,
        app,
      );
      for (var n = 0; n < numberOfPages; n++) {
        final nested = ReflectiveInjector.resolveAndCreate(
          simpleTreePageBindings,
          page,
        );
        final panel = ReflectiveInjector.resolveAndCreate(
          simpleTreePanelBindings,
          nested,
        );
        for (var x = 0; x < numberOfTabs; x++) {
          final tab = ReflectiveInjector.resolveAndCreate(
            simpleTreeTabBindings,
            panel,
          );
          // Will initialize the entire DI tree.
          tab.get(TabService);
        }
      }
    }
  }
}
