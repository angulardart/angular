@JS()
library golden;

import 'package:js/js.dart';
import 'package:angular/angular.dart';

import 'interpolate.template.dart' as ng;

/// Avoids Dart2JS thinking something is constant/unchanging.
@JS()
external T deopt<T>([Object? any]);

void main() {
  runApp(ng.createGoldenComponentFactory());
}

@Component(
  selector: 'golden',
  directives: [
    SimpleStringInterpolate,
    SimpleUnknownInterpolate,
    KnownFinalValuesInterpolate,
    AdjacentInterpolate,
    LiteralsInterpolate,
    PropertyInterpolate,
    InputInterpolate,
    MaximumInterpolateLimit,
    NullCheckedInterpolate,
  ],
  template: '''
    <simple-string [value]="string"></simple-string>
    <simple-unknown [value]="anything"></simple-unknown>
    <known-finals></known-finals>
    <adjacency></adjacency>
    <literals></literals>
    <property></property>
    <inputs></inputs>
    <max-interpolate-limit></max-interpolate-limit>
    <null-checked></null-checked>
  ''',
)
class GoldenComponent {
  GoldenComponent() {
    deopt(() {
      string = deopt('value');
      anything = deopt('anything');
    });
  }

  late String string;
  late Object anything;
}

@Component(
  selector: 'simple-string',
  template: '{{value}}',
)
class SimpleStringInterpolate {
  @Input()
  String? value;
}

@Component(
  selector: 'simple-unknown',
  template: '{{value}}',
)
class SimpleUnknownInterpolate {
  @Input()
  Object? value;
}

@Component(
  selector: 'known-finals',
  template: '''
    <span>{{aConstString}}</span>
    <span>{{aFinalString}}</span>
    <span>{{aFinalNumber}}</span>
  ''',
)
class KnownFinalValuesInterpolate {
  static const aConstString = 'A';
  static final aFinalString = 'B';
  static final aFinalNumber = 3;
}

@Component(
  selector: 'adjacency',
  template: '''
    <span>{{greeting}} {{place}}!</span>
    <span>{{greeting}}! We are happy to have {{name}} in our {{place}}!</span>
  ''',
)
class AdjacentInterpolate {
  String greeting = deopt();
  String place = deopt();
  String name = deopt();
}

@Component(
  selector: 'literals',
  template: '''
    <span>{{"Hello"}} {{"World"}}!</span>
    <span>{{1}} {{2}} {{3}}</span>
  ''',
)
class LiteralsInterpolate {}

@Component(
  selector: 'property',
  template: '''
    <span title="{{title1}} {{title2}}"></span>
  ''',
)
class PropertyInterpolate {
  String title1 = deopt();
  String title2 = deopt();
}

@Component(
  selector: 'inputs',
  directives: [
    ChildComponent,
  ],
  template: '''
    <child value="{{a}} {{b}}"></child>
  ''',
)
class InputInterpolate {
  String a = deopt();
  String b = deopt();
}

@Component(
  selector: 'child',
  template: '',
)
class ChildComponent {
  @Input()
  set value(Object any) {
    deopt(any);
  }
}

@Component(
  selector: 'max-interpolate-limit',
  template: '''
    <span>
      {{stringA}}
      {{stringB}}
      {{stringC}}
      {{stringD}}
      {{stringE}}
      {{stringF}}
      {{stringG}}
      {{stringH}}
      {{stringI}}
      {{stringJ}}
    </span>
    <span>
      {{hide(stringA)}}
      {{hide(stringB)}}
      {{hide(stringC)}}
      {{hide(stringD)}}
      {{hide(stringE)}}
      {{hide(stringF)}}
      {{hide(stringG)}}
      {{hide(stringH)}}
      {{hide(stringI)}}
      {{hide(stringJ)}}
    </span>
    <!-- Add two uses of interpolateN to prevent dart2js optimizing it for specific parameters -->
    <button title="{{stringA}},{{stringB}},{{stringC}},{{stringD}},{{stringE}},{{stringF}},{{stringG}},{{stringH}},{{stringI}}"></button>
    <button title="{{stringA}},{{stringB}},{{stringC}},{{stringD}}"></button>
  ''',
)
class MaximumInterpolateLimit {
  String stringA = deopt(); // 0
  String stringB = deopt(); // 1
  String stringC = deopt(); // 2
  String stringD = deopt(); // 3
  String stringE = deopt(); // 4
  String stringF = deopt(); // 5
  String stringG = deopt(); // 6
  String stringH = deopt(); // 7
  String stringI = deopt(); // 8
  String stringJ = deopt(); // 9

  static Object hide(Object a) => a;
}

@Component(
  selector: 'null-checked',
  template: '''
    {{maybeNull ?? ''}}
    {{maybeNull?.toUpperCase()}}
    {{maybeNull?.hashCode}}
  ''',
)
class NullCheckedInterpolate {
  String? maybeNull;
}
