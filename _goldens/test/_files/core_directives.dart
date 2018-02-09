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
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class TestFooComponent {
  final bool foo = true;
  final List<String> bars = ['bar'];

  void onClick(String value) {
    print('Clicked on $value');
  }
}
