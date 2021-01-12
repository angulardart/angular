@JS()
library golden;

import 'package:js/js.dart';
import 'package:angular/angular.dart';

import 'after_changes.template.dart' as ng;

/// Avoids Dart2JS thinking something is constant/unchanging.
@JS()
external T deopt<T>([Object? any]);

void main() {
  runApp(ng.createGoldenComponentFactory());
}

@Component(
  selector: 'golden',
  directives: [UsesAfterChanges],
  template: '<uses-after-changes [a]="a" [b]="b" [c]="c"></uses-after-changes>',
)
class GoldenComponent {
  late String a;
  late String b;
  late String c;

  GoldenComponent() {
    deopt(() {
      a = deopt('a');
      b = deopt('b');
      c = deopt('c');
    });
  }
}

@Component(
  selector: 'uses-after-changes',
  template: '',
)
class UsesAfterChanges implements AfterChanges {
  @Input()
  String? a;

  @Input()
  String? b;

  @Input()
  String? c;

  @override
  void ngAfterChanges() {
    deopt([a, b, c]);
  }
}
