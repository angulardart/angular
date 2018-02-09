import 'dart:async';

import 'package:angular/angular.dart';

@Component(
  selector: 'uses-native-events',
  template: r'''
    <button (click)="onClick()"></button>
  ''',
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
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
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class UsesAngularEvents {}

@Component(
  selector: 'has-angular-events',
  template: '',
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class HasAngularEvents {
  @Output()
  Stream<Null> get foo => const Stream.empty();
}
