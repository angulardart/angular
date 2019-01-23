import 'package:angular/angular.dart';

@Component(
  selector: 'Emulated',
  template: '<div>Emulated</div>',
  encapsulation: ViewEncapsulation.Emulated,
  styles: [
    ':host { border: 1px solid #000; } ',
    'div { color: red; }',
  ],
  styleUrls: [
    'view_encapsulated_styles.css',
  ],
)
class EmulatedComponent {}

@Component(
  selector: 'None',
  template: '<div>None</div>',
  encapsulation: ViewEncapsulation.None,
  styles: [
    ':host { border: 1px solid #000; } ',
    'div { color: red; }',
  ],
  styleUrls: [
    'view_encapsulated_styles.css',
  ],
)
class NoneComponent {}
