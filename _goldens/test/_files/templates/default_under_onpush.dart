import 'dart:async';
import 'package:angular/angular.dart';

/// A demo of "default-under-onpush", an anti-pattern where a child
/// component with a Default change detection startegy is created in
/// the view of a component with an OnPush change detection strategy.

@Component(
  selector: 'default-comp',
  template: '''
    The current time is {{time}}
  ''',
)
class DefaultComp {
  DefaultComp() {
    Timer(Duration(seconds: 1), () {
      time = DateTime.now().toString();
    });
  }
  String time = "...";
}

@Component(
    selector: 'onpush-comp',
    template: '''
    <b><default-comp></default-comp></b>
  ''',
    directives: const [DefaultComp],
    changeDetection: ChangeDetectionStrategy.OnPush)
class OnPushComp {}
