@JS()
library golden;

import 'package:js/js.dart';
import 'package:angular/angular.dart';

import 'on_init_and_destroy.template.dart' as ng;

/// Avoids Dart2JS thinking something is constant/unchanging.
@JS()
external T deopt<T>([Object? any]);

void main() {
  runApp(ng.createGoldenComponentFactory());
}

@Component(
  selector: 'golden',
  directives: [
    UsesOnInit,
    UsesOnDestroy,
  ],
  template: '''
    <uses-on-init [a]="a" [b]="b" [c]="c">
    </uses-on-init>
    <uses-on-destroy [a]="a" [b]="b" [c]="c">
    </uses-on-destroy>
  ''',
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
  selector: 'uses-on-init',
  template: '',
)
class UsesOnInit implements OnInit {
  @Input()
  String? a;

  @Input()
  String? b;

  @Input()
  String? c;

  @override
  void ngOnInit() {
    deopt([a, b, c]);
  }
}

@Component(
  selector: 'uses-on-destroy',
  template: '',
)
class UsesOnDestroy implements OnDestroy {
  @Input()
  String? a;

  @Input()
  String? b;

  @Input()
  String? c;

  @override
  void ngOnDestroy() {
    deopt([a, b, c]);
  }
}
