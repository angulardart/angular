import 'package:angular/angular.dart';

@Component(
  selector: 'test-foo',
  template: '''
    <div *ngIf="foo">Foo</div>
    <div *ngFor="let bar of bars; let index=index; let odd=odd">
      <span (click)="onClick(bar)">{{bar}}. #{{index}} odd?{{odd}}</span>
    </div>
    ''',
  directives: [NgIf, NgFor],
)
class TestFooComponent {
  final bool foo = true;
  final List<String> bars = ['bar'];

  void onClick(String value) {
    print('Clicked on $value');
  }
}
