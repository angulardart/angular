@JS()
library golden;

import 'package:js/js.dart';
import 'package:angular/angular.dart';

import 'directive_star_syntax.template.dart' as ng;

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
    <div *ngIf="show">
      Show some {{value}}.
    </div>
    <ul>
      <li *ngFor="let v of values; let index = index; let odd = odd">
        {{index}}: {{v}} ({{odd}})
      </li>
    </ul>
  ''',
)
class GoldenComponent {
  bool show = deopt();
  String value = deopt();
  List<int> values = deopt();
}
