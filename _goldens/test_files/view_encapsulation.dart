import 'package:angular/angular.dart';

@Component(
  selector: 'Emulated',
  template: '<div>Emulated</div>',
  encapsulation: ViewEncapsulation.Emulated,
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class EmulatedComponent {}

@Component(
  selector: 'None',
  template: '<div>None</div>',
  encapsulation: ViewEncapsulation.None,
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class NoneComponent {}
