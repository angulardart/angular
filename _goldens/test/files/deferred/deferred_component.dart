import 'package:angular/angular.dart';

import 'external_service.dart';

@Component(
  selector: 'deferred-child-1',
  template: 'Deferred Child 1',
)
class DeferredChild1Component {}

@Component(
  selector: 'deferred-child-2',
  template: 'Deferred Child 2',
)
class DeferredChild2Component {}

@Component(
  selector: 'deferred-child-3',
  template: 'Deferred Child 3',
)
class DeferredChild3Component {}

@Component(
  selector: 'deferred-child-on-push',
  template: 'Deferred Child On Push',
  changeDetection: ChangeDetectionStrategy.OnPush,
)
class DeferredChildOnPush {}

@Component(
  selector: 'not-deferred-child',
  template: '',
)
class NotDeferredChildComponent {}

@Component(
  selector: 'deferred-child-without-ng-content',
  template: '<div>Child</div>',
)
class DeferredChildComponentWithoutNgContent {}

@Component(
  selector: 'deferred-child-with-ng-content',
  template: '<div><ng-content></ng-content></div>',
)
class DeferredChildComponentWithNgContent {}

@Component(
  selector: 'deferred-child-with-services',
  template: '',
  providers: [
    ClassProvider(ExternalServiceImmediatelyCreated),
    ClassProvider(ExternalServiceLazilyCreatedMaybe),
  ],
)
class DeferredChildComponentWithServices {
  DeferredChildComponentWithServices(ExternalServiceImmediatelyCreated _);
}
