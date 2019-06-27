import 'dart:async';

import 'package:angular/angular.dart';

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
  directives: [
    HasAngularEvents,
  ],
  template: r'''
    <has-angular-events (foo)="onFoo()"></has-angular-events>
  ''',
)
class UsesAngularEvents {
  void onFoo() {}
}

@Component(
  selector: 'has-angular-events',
  template: '',
)
class HasAngularEvents {
  @Output()
  Stream<Null> get foo => const Stream.empty();
}

@Component(
  selector: 'material-button-like',
  template: '',
)
class HasManyNativeHostEvents {
  @HostListener('mousedown')
  void onMouseDown(Object e) {}

  @HostListener('mouseup')
  void onMouseUp(Object e) {}

  @HostListener('click')
  void onClick(Object e) {}

  @HostListener('keypress')
  void onKeyPress(Object e) {}

  @HostListener('focus')
  void onFocus(Object e) {}

  @HostListener('blur')
  void onBlur(Object e) {}
}
