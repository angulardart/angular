@JS()
library golden;

import 'package:js/js.dart';
import 'package:angular/angular.dart';

import 'nested_structural_directives.template.dart' as ng;

/// Avoids Dart2JS thinking something is constant/unchanging.
@JS()
external T deopt<T>([Object? any]);

void main() {
  runApp(ng.createGoldenComponentFactory());
}

@Component(
  selector: 'golden',
  directives: [
    NgFor,
    NgIf,
  ],
  template: '''
    <table>
      <tr *ngFor="let row of matrix">
        <td *ngFor="let col of row">
          <ng-container *ngIf="col.isEven">
            Even: {{col}}
          </ng-container>
          <ng-container *ngIf="col.isOdd">
            Odd: {{col}}
          </ng-container>
        </td>
      </tr>
    </table>
  ''',
)
class GoldenComponent {
  List<List<int>> matrix = deopt();
}
