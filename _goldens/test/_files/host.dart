import 'dart:async';

import 'package:angular/angular.dart';

@Component(
  selector: 'host',
  template: '',
)
class HostComponentNewSyntax {
  @HostBinding('class')
  static const hostClass = 'themeable';
}

@Component(
  selector: 'uses-host',
  directives: [
    HostComponent,
    ListensToFooEvent,
  ],
  template: r'''
    <host listens-to-foo></host>
  ''',
)
class UsesHostComponentWithDirective {}

@Component(
  selector: 'host',
  template: '',
)
class HostComponent {
  @HostBinding('attr.has-shiny.if')
  static const bool hasShinyAttribute = true;

  @HostBinding('attr.has-terrible.if')
  static bool get hasTerrible => false;

  @HostBinding()
  @HostBinding('attr.aria-title')
  String get title => 'Hello';

  @HostBinding('attr.aria-disabled.if')
  @HostBinding('class.is-disabled')
  bool get isDisabled => true;

  @HostBinding('class.foo')
  static const bool hostClassFoo = true;

  @HostBinding('style.color')
  static const String hostStyleColor = 'red';

  @HostListener('click', [r'$event'])
  void onClick(event) {}

  // Since this listener has more than one argument, it
  // is not simple and uses a different code path to
  // generate methods.
  @HostListener('tripleclick', [r'$event', 'title'])
  void onClickNotSimple(event, arg2) {}

  @HostListener('keydown')
  void onKeyDown() {}

  @Output('onFoo')
  final fooEvents = StreamController<void>().stream;
}

@Directive(
  selector: '[listens-to-foo]',
)
class ListensToFooEvent {
  @HostListener('onFoo')
  void onOutputFoo() {}
}
