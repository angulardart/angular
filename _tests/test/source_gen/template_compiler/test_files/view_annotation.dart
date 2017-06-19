import 'package:angular/angular.dart';

@Component(
  selector: 'test-foo',
  preserveWhitespace: false,
  template: '<div *ngIf="true">Foo</div>',
  directives: const [NgIf],
  styles: const ['div { font-size: 10px; }'],
)
class TestFooComponent {}
