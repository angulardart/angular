import 'package:angular/angular.dart';

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
  selector: 'deferred-child-without-ng-content',
  template: '<div>Child</div>',
)
class DeferredChildComponentWithoutNgContent {}

@Component(
  selector: 'deferred-child-with-ng-content',
  template: '<div><ng-content></ng-content></div>',
)
class DeferredChildComponentWithNgContent {}
