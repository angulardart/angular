import 'package:angular/angular.dart';

@Component(
  selector: 'Emulated',
  template: '<div>Emulated</div>',
  encapsulation: ViewEncapsulation.Emulated,
  // TODO(b/65383776): Change preserveWhitespace to false to improve codesize.
  preserveWhitespace: true,
)
class EmulatedComponent {}

@Component(
  selector: 'None',
  template: '<div>None</div>',
  encapsulation: ViewEncapsulation.None,
  // TODO(b/65383776): Change preserveWhitespace to false to improve codesize.
  preserveWhitespace: true,
)
class NoneComponent {}
