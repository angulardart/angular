@JS()
library golden;

import 'dart:async';

import 'package:js/js.dart';
import 'package:angular/angular.dart';

import 'host_annotations.template.dart' as ng;

/// Avoids Dart2JS thinking something is constant/unchanging.
@JS()
external T deopt<T>([Object? any]);

void main() {
  runApp(ng.createGoldenComponentFactory());
}

@Component(
  selector: 'host',
  directives: [
    HasOutput,
    ListensToOutput,
  ],
  template: r'''
    <has-output listens-to-output>
    </has-output>
  ''',
)
class GoldenComponent {
  @HostBinding('attr.const-add-attr-bool.if')
  static const constAddAttributeBool = true;

  @HostBinding('attr.final-add-attr-bool.if')
  static final finalAddAttributeBool = deopt();

  @HostBinding('attr.getter-add-attr-bool.if')
  static bool get getterAddAttributeBool => deopt();

  @HostBinding('attr.getter-add-attr-string')
  static String get getterAddAttributeString => deopt();

  @HostBinding('class.const-add-class')
  static const constAddClass = true;

  @HostBinding('style.color')
  static const constAddStyleColor = 'red';

  @HostBinding('title')
  @HostBinding('attr.aria-title')
  String get multiBindTitle => 'Hello';

  @HostBinding('attr.aria-disabled.if')
  @HostBinding('class.is-disabled')
  bool get multiBindDisabled => true;

  @HostListener('click')
  void onClickNoArguments() {
    deopt('onClickNoArguments');
  }

  @HostListener('dblclick')
  void onDblClickInferArgument(Object event) {
    deopt(['onDblClickInferArgument', event]);
  }

  @HostListener('mousedown', [r'$event'])
  void onMouseDownManualArgument(Object event) {
    deopt(['onMouseDownManualArgument', event]);
  }

  @HostListener('mouseup', [r'$event', 'multiBindTitle'])
  void onMouseUpMultipleArguments(Object a, Object b) {
    deopt(['onMouseUpMultipleArguments', a, b]);
  }

  @HostListener('keydown.space')
  void onSpecialKeyHandler() {
    deopt('onSpecialKeyHandler');
  }
}

@Directive(
  selector: '[listens-to-output]',
)
class ListensToOutput {
  @HostListener('onFoo')
  void onCustomEvent() {
    deopt('onCustomEvent');
  }
}

@Component(
  selector: 'has-output',
  template: '',
)
class HasOutput {
  @Output('onFoo')
  final fooEvents = StreamController<void>().stream;
}
