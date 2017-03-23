import 'dart:async';

import 'package:angular2/angular2.dart';

@Component(
  selector: 'uses-native-events',
  template: r'''
    <button (click)="onClick()"></button>
  ''',
)
class UsesNativeEvents {
  @HostListener('focus')
  void onFocus() {}

  void onClick() {}
}

@Component(
  selector: 'uses-angular-events',
  directives: const [
    HasAngularEvents,
  ],
  template: r'''
    <has-angular-events (foo)="onFoo()"></has-angular-events>
  ''',
)
class UsesAngularEvents {}

@Component(
  selector: 'has-angular-events',
  template: '',
)
class HasAngularEvents {
  @Output()
  Stream<Null> get foo => const Stream.empty();
}
