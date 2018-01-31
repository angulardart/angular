import 'package:angular/angular.dart';

@Component(
  selector: 'deferred-component',
  template: '<div>Child</div>',
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class DeferredChildComponent {}
