import 'package:angular/angular.dart';

@Component(
  selector: 'test-foo',
  template: '''
    <div *ngIf="foo">Foo</div>
    <div *ngFor="let bar of bars">
      <span (click)="onClick(bar)">{{bar}}</span>
    </div>
    ''',
  directives: const [NgIf, NgFor],
)
class TestFooComponent {
  final bool foo = true;
  final List<String> bars = ['bar'];

  void onClick(String value) {
    print('Clicked on $value');
  }
}
