import 'package:angular/angular.dart';

import '../common.dart';
import 'src/tree_bindings.dart';

/// Initializes and injects a tree of DI services typical to a small web app.
///
/// Set [ready] to true to create the tree.
@Component(
  selector: 'create-20-bindings-benchmark',
  directives: [
    CreateTreeBindingsAppComponent,
    NgIf,
  ],
  template: r'''
    <create-tree-bindings-app *ngIf="ready"></create-tree-bindings-app>
  ''',
)
class CreateTreeBindingsBenchmark implements Benchmark {
  @Input()
  bool ready = false;

  @override
  void start() => ready = true;

  @override
  void reset() => ready = false;
}

@Component(
  selector: 'create-tree-bindings-app',
  providers: [
    simpleTreeAppBindings,
  ],
  directives: [
    CreateTreeBindingsPageComponent,
    NgFor,
  ],
  template: r'''
    <div *ngFor="let page of pages">
      <create-tree-bindings-page nested></create-tree-bindings-page>
    </div>
  ''',
)
class CreateTreeBindingsAppComponent {
  final pages = List<Null>(numberOfPages);
}

@Component(
  selector: 'create-tree-bindings-page',
  providers: [
    simpleTreePageBindings,
  ],
  directives: [
    CreateTreeBindingsPageComponent,
    CreateTreeBindingsPanelComponent,
    NgIf,
  ],
  template: r'''
    <template [ngIf]="nested">
      <create-tree-bindings-page></create-tree-bindings-page>
    </template>
    <create-tree-bindings-panel></create-tree-bindings-panel>
  ''',
)
class CreateTreeBindingsPageComponent {
  @Input()
  bool nested = false;
}

@Component(
  selector: 'create-tree-bindings-panel',
  providers: [
    simpleTreePanelBindings,
  ],
  directives: [
    CreateTreeBindingsTabComponent,
    NgFor,
  ],
  template: r'''
    <div *ngFor="let tab of tabs">
      <create-tree-bindings-tab></create-tree-bindings-tab>
    </div>
  ''',
)
class CreateTreeBindingsPanelComponent {
  final tabs = List<Null>(numberOfTabs);
}

@Component(
  selector: 'create-tree-bindings-tab',
  providers: [
    simpleTreeTabBindings,
  ],
  template: '[TAB]',
)
class CreateTreeBindingsTabComponent {
  CreateTreeBindingsTabComponent(Injector injector) {
    // Will initialize the entire DI tree.
    injector.get(TabService);
  }
}
