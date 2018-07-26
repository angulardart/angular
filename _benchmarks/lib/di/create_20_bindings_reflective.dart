import 'package:angular/angular.dart';

import '../common.dart';
import 'src/flat_20_bindings.dart';

/// Initializes and injects 20 DI bindings when [ready] is turned to `true`.
///
/// All bindings are eagerly initialized (optimized by the compiler).
@Component(
  selector: 'create-20-bindings-reflective-benchmark',
  directives: [
    NgIf,
  ],
  template: '',
)
class Create20BindingsReflectiveBenchmark implements Benchmark {
  @override
  void start() => ready = true;

  @override
  void reset() => ready = false;

  @Input()
  set ready(bool ready) {
    if (ready) {
      final injector = ReflectiveInjector.resolveAndCreate(flat20Bindings);
      flat20Bindings.forEach(injector.get);
    }
  }
}
