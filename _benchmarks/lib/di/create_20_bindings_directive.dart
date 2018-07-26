import 'package:angular/angular.dart';

import '../common.dart';
import 'src/flat_20_bindings.dart';

/// Initializes and injects 20 DI bindings when [ready] is turned to `true`.
///
/// All bindings are eagerly initialized (optimized by the compiler).
@Component(
  selector: 'create-20-bindings-benchmark',
  directives: [
    Create20BindingsEagerComponent,
    NgIf,
  ],
  template: r'''
    <create-20-bindings-eager *ngIf="ready"></create-20-bindings-eager>
  ''',
)
class Create20BindingsEagerBenchmark extends Benchmark {
  @Input()
  bool ready = false;

  @override
  void start() => ready = true;

  @override
  void reset() => ready = false;
}

@Component(
  selector: 'create-20-bindings-eager',
  providers: [
    flat20Bindings,
  ],
  template: 'DONE',
)
class Create20BindingsEagerComponent {
  Create20BindingsEagerComponent(
    Service1 s1,
    Service2 s2,
    Service3 s3,
    Service4 s4,
    Service5 s5,
    Service6 s6,
    Service7 s7,
    Service8 s8,
    Service9 s9,
    Service10 s10,
    Service11 s11,
    Service12 s12,
    Service13 s13,
    Service14 s14,
    Service15 s15,
    Service16 s16,
    Service17 s17,
    Service18 s18,
    Service19 s19,
    Service20 s20,
  );
}

/// Initializes and injects 20 DI bindings when [ready] is turned to `true`.
///
/// All bindings are lazily initialized (not optimized by the compiler).
@Component(
  selector: 'create-20-bindings-benchmark',
  directives: [
    Create20BindingsLazyComponent,
    NgIf,
  ],
  template: r'''
    <create-20-bindings-lazy *ngIf="ready"></create-20-bindings-lazy>
  ''',
)
class Create20BindingsLazyBenchmark implements Benchmark {
  @Input()
  bool ready = false;

  @override
  void start() => ready = true;

  @override
  void reset() => ready = false;
}

@Component(
  selector: 'create-20-bindings-lazy',
  providers: [
    flat20Bindings,
  ],
  template: 'DONE',
)
class Create20BindingsLazyComponent {
  Create20BindingsLazyComponent(Injector injector) {
    flat20Bindings.forEach(injector.get);
  }
}
