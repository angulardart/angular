import 'package:angular/angular.dart';

/// A token representing the [ComponentFactory] to be loaded.
const runBenchmarkOn = const OpaqueToken('runBenchmarkOn');

/// A component interface that is able to run and reset a benchmark.
abstract class Benchmark {
  /// Set to `true` to trigger the benchmark, or `false` to reset it.
  @Input()
  set ready(bool ready);
}

/// Setup and instrumentation to run a [Benchmark] component.
///
/// This component is expected to be loaded as the root component:
/// ```dart
/// void main() {
///   bootstrap(
///     BenchmarkComponent,
///     [provide(runBenchmarkOn, useValue: gen.SomeBenchmarkNgFactory)],
///     gen.initReflector,
///   );
/// }
/// ```
@Component(
  selector: 'benchmark',
  template: r'''
    <template #location></template>
    <button id="run" (click)="run()"></button>
    <button id="reset" (click)="reset()"></button>
  ''',
)
class BenchmarkComponent implements OnInit {
  final ComponentFactory<Benchmark> _factory;
  final ComponentLoader _loader;

  Benchmark _component;

  BenchmarkComponent(this._loader, @Inject(runBenchmarkOn) this._factory);

  @ViewChild('location', read: ViewContainerRef)
  ViewContainerRef location;

  @override
  void ngOnInit() {
    _component = _loader.loadNextToLocation(_factory, location).instance;
  }

  void run() {
    _component.ready = true;
  }

  void reset() {
    _component.ready = false;
  }
}
