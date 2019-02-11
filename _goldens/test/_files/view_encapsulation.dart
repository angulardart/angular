import 'package:angular/angular.dart';

@Component(
  selector: 'Emulated',
  template: r'''
    <div>Emulated in Component</div>
    <template>
      <div>Emulated in Template</div>
    </template>
  ''',
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
  template: r'''
    <div>Emulated in Component</div>
    <template>
      <div>Emulated in Template</div>
    </template>
  ''',
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
