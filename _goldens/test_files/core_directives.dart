import 'package:angular/angular.dart';

@Component(
  selector: 'test-foo',
  template: '''
    <div *ngIf="foo">Foo</div>
    <div *ngFor="let bar of bars">
      <span>{{bar}}</span>
    </div>
    ''',
  directives: const [NgIf, NgFor],
  // TODO(b/65383776): Change preserveWhitespace to false to improve codesize.
  preserveWhitespace: true,
)
class TestFooComponent {
  final bool foo = true;
  final List<String> bars = ['bar'];
}
