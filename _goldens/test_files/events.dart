import 'dart:async';

import 'package:angular/angular.dart';

@Component(
  selector: 'uses-native-events',
  template: r'''
    <button (click)="onClick()"></button>
  ''',
  // TODO(b/65383776): Change preserveWhitespace to false to improve codesize.
  preserveWhitespace: true,
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
  // TODO(b/65383776): Change preserveWhitespace to false to improve codesize.
  preserveWhitespace: true,
)
class UsesAngularEvents {}

@Component(
  selector: 'has-angular-events',
  template: '',
  // TODO(b/65383776): Change preserveWhitespace to false to improve codesize.
  preserveWhitespace: true,
)
class HasAngularEvents {
  @Output()
  Stream<Null> get foo => const Stream.empty();
}
