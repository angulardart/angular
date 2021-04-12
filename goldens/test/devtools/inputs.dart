@JS()
library golden;

import 'package:js/js.dart';
import 'package:angular/angular.dart';

import 'inputs.template.dart' as ng;

/// Avoids Dart2JS thinking something is constant/unchanging.
@JS()
external T deopt<T>([Object? any]);

void main() {
  runApp(ng.createGoldenComponentFactory());
}

@Component(
  selector: 'golden',
  directives: [
    HasInputComponent,
    HasInputsComponent,
    HasRenamedInputComponent,
  ],
  template: r'''
    <!-- Various binding sources -->
    <has-input [name]="immutableValue"></has-input>
    <has-input [name]="mutableValue"></has-input>
    <has-input [name]="'literalValue'"></has-input>
    <has-input name="attributeValue"></has-input>
    <has-input [name]="'Message'" @i18n:name="Description"></has-input>

    <!-- Multiple inputs -->
    <has-inputs [name]="mutableValue" [number]="12"></has-inputs>

    <!-- Renamed input -->
    <has-renamed-input [templateName]="mutableValue"></has-renamed-input>
  ''',
)
class GoldenComponent {
  final immutableValue = deopt<String>();
  var mutableValue = deopt<String>();
}

@Component(
  selector: 'has-input',
  template: '',
)
class HasInputComponent {
  @Input()
  set name(String value) {
    deopt(value);
  }
}

@Component(
  selector: 'has-inputs',
  template: '',
)
class HasInputsComponent {
  @Input()
  set name(String value) {
    deopt(value);
  }

  @Input()
  set number(int value) {
    deopt(value);
  }
}

@Component(
  selector: 'has-renamed-input',
  template: '',
)
class HasRenamedInputComponent {
  @Input('templateName')
  set propertyName(String value) {
    deopt(value);
  }
}
