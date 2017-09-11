import 'package:angular/angular.dart';

@Component(
    selector: 'test-foo',
    template: '''
    <div *ngIf="foo">Foo</div>
    <div *ngFor="let bar of bars">
      <span>{{bar}}</span>
    </div>
    ''',
    directives: const [NgIf, NgFor])
class TestFooComponent {
  final bool foo = true;
  final List<String> bars = ['bar'];
}
