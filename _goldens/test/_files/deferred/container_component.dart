import 'package:angular/angular.dart';
import 'package:_goldens/component.dart';

import 'deferred_component.dart';

@Component(
  selector: 'test-container',
  template: r'''
    <deferred-child-1 @deferred></deferred-child-1>
    <template [ngIf]="showDeferredChild">
      <deferred-child-2 @deferred></deferred-child-2>
    </template>
    <div *ngIf="showDeferredChild">
      <deferred-child-3 @deferred #queryMe></deferred-child-3>
    </div>
    <deferred-child-on-push @deferred></deferred-child-on-push>
    <deferred-child-without-ng-content @deferred>
    </deferred-child-without-ng-content>
    <deferred-child-with-ng-content @deferred>
      Hello World
    </deferred-child-with-ng-content>
    <not-deferred-child></not-deferred-child>
    <deferred-child-with-services @deferred></deferred-child-with-services>
  ''',
  directives: [
    DeferredChild1Component,
    DeferredChild2Component,
    DeferredChild3Component,
    DeferredChildOnPush,
    DeferredChildComponentWithoutNgContent,
    DeferredChildComponentWithNgContent,
    DeferredChildComponentWithServices,
    NgIf,
    NotDeferredChildComponent,
    SampleComponent,
  ],
)
class TestContainerComponent {
  bool showDeferredChild = true;

  @ViewChild('queryMe')
  DeferredChild3Component queryDeferredChild;
}
