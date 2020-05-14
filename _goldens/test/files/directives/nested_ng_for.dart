import 'package:angular/angular.dart';

@Component(
  selector: 'nested-ng-for',
  template: '''
    <span *ngFor="let row of matrix">
      <div *ngFor="let value of row">{{value}}</div>
    </span>
  ''',
  directives: [NgFor],
)
class NestedNgForComponent {
  List<List<int>> matrix;
}
