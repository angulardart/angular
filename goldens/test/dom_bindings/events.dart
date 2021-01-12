@JS()
library golden;

import 'package:js/js.dart';
import 'package:angular/angular.dart';

import 'events.template.dart' as ng;

/// Avoids Dart2JS thinking something is constant/unchanging.
@JS()
external T deopt<T>([Object? any]);

void main() {
  runApp(ng.createGoldenComponentFactory());
}

@Component(
  selector: 'golden',
  directives: [
    UsesDomEvents,
    UsesOutputs,
  ],
  template: '''
    <uses-dom-events></uses-dom-events>
    <uses-ng-events></uses-ng-events>
  ''',
)
class GoldenComponent {}

@Component(
  selector: 'uses-dom-events',
  template: r'''
    <button (click)="tearOffNoArguments"></button>
    <button (click)="tearOffWithArguments"></button>
    <button (click)="callEventWithArguments($event)"></button>
  ''',
)
class UsesDomEvents {
  void tearOffNoArguments() {
    deopt('tearOffNoArguments');
  }

  void tearOffWithArguments(Object e) {
    deopt(['tearOffWithArguments', e]);
  }

  void callEventWithArguments(Object e) {
    deopt(['callEventWithArguments', e]);
  }
}

@Component(
  selector: 'uses-ng-events',
  directives: [
    HasNgEvents,
  ],
  template: r'''
    <has-ng-events (foo)="tearOffNoArguments"
                   (bar)="tearOffWithArguments"
                   (baz)="callEventWithArguments($event)">
    </has-ng-events>
  ''',
)
class UsesOutputs {
  void tearOffNoArguments() {
    deopt('tearOffNoArguments');
  }

  void tearOffWithArguments(Object e) {
    deopt(['tearOffWithArguments', e]);
  }

  void callEventWithArguments(Object e) {
    deopt(['callEventWithArguments', e]);
  }
}

@Component(
  selector: 'has-ng-events',
  template: '',
)
class HasNgEvents {
  @Output()
  final foo = const Stream<void>.empty();

  @Output()
  final bar = const Stream<void>.empty();

  @Output()
  final baz = const Stream<Object>.empty();
}
