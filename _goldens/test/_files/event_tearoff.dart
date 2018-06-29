import 'package:angular/angular.dart';

@Component(
  selector: 'uses-event-tearoff',
  template: r'''
    <button (click)="onClick" (blur)="onBlur"></button>
  ''',
)
class UsesEventTearoff {
  void onClick(Object e) {}

  void onBlur() {}
}
