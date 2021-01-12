library golden;

import 'package:angular/angular.dart';

import 'type_inference.template.dart' as ng;

void main() {
  runApp(ng.createGoldenComponentFactory());
}

@Component(
  selector: 'golden',
  directives: [NgFor],
  template: '''
    <!-- Operators -->
    {{stringA + stringB}}

    <!-- Methods -->
    {{stringA.toUpperCase()}}

    <!-- Generic Methods -->
    {{max(int1, int2).isEven}}

    <ng-container *ngFor="let duration of durationList">
      {{duration.inMilliseconds}}
    </ng-container>

    <ng-container *ngFor="let durationList of nestedLists">
      <ng-container *ngFor="let duration of durationList">
        {{duration.inMilliseconds}}
      </ng-container>
    </ng-container>
  ''',
)
class GoldenComponent {
  static T max<T extends num>(T a, T b) {
    return a.compareTo(b) < 0 ? b : a;
  }

  var stringA = '1';
  var stringB = '2';

  var int1 = 1;
  var int2 = 2;

  var durationList = [
    Duration(seconds: 1),
  ];

  var nestedLists = [
    [
      Duration(seconds: 1),
    ],
  ];
}
