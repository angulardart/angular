@JS()
library golden;

import 'package:js/js.dart';
import 'package:angular/angular.dart';

import 'directive_change_detector.template.dart' as ng;

/// Avoids Dart2JS thinking something is constant/unchanging.
@JS()
external T deopt<T>([Object? any]);

void main() {
  runApp(ng.createGoldenComponentFactory());
}

@Component(
  selector: 'golden',
  directives: [
    NgModelLike,
  ],
  template: r'''
    <input [(ngModel)]="value" />
  ''',
)
class GoldenComponent {
  String value = deopt();
}

@Directive(
  selector: '[ngModel]:not([ngControl]):not([ngFormControl])',
)
class NgModelLike implements AfterChanges, OnInit {
  @Output('ngModelChange')
  Stream<void> get modelChange => const Stream.empty();

  @Input('ngModel')
  set model(Object ngModel) {}

  @override
  void ngAfterChanges() {}

  @override
  void ngOnInit() {}
}
