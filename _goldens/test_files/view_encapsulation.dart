import 'package:angular/angular.dart';

@Component(
  selector: 'Emulated',
  template: '<div>Emulated</div>',
  encapsulation: ViewEncapsulation.Emulated,
)
class EmulatedComponent {}

@Component(
  selector: 'None',
  template: '<div>None</div>',
  encapsulation: ViewEncapsulation.None,
)
class NoneComponent {}
