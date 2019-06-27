import 'package:angular/angular.dart';

@Component(
  selector: 'interpolation',
  preserveWhitespace: true,
  template: r'''
    <div>
      {{foo}}
    </div>
  ''',
)
class InterpolationComponent {
  var foo = 'hello';
}

@Component(
  selector: 'interpolation',
  template: r'''
    <div>
      {{foo}}
    </div>
  ''',
)
class InterpolationComponentNoWhitespace {
  var foo = 'hello';
}

@Component(selector: 'interpolation', template: r'''
    <div>
      {{greeting}} {{noun}}!
    </div>
  ''')
class InterpolationTwoAdjacent {
  var greeting = 'Hello';
  var noun = 'World';
}

@Component(
  selector: 'interpolation',
  template: r'''
    <div>
      Welcome {{name}} to the {{business}} of {{location}}!
    </div>
  ''',
)
class InterpolationLongerSentence {
  var name = 'Joe';
  var business = 'Bank';
  var location = 'tomorrow';
}

@Component(
  selector: 'interpolation',
  template: r'''
    <div>{{"Welcome"}} {{"Home"}}!</div>
  ''',
)
class InterpolationLiterals {}

@Component(
  selector: 'interpolation',
  directives: [
    NgFor,
  ],
  template: r'''
    <ng-container *ngFor="let bar of bars">
      <ng-container *ngFor="let foo of bar">
        Hello {{callMethod(bar)}}: {{foo}}!
      </ng-container>
    </ng-container>
  ''',
)
class InterpolationLocals {
  final bars = [
    [1],
    [2],
    [3, 4]
  ];
  String callMethod(Object input) => input.toString();
}

// Demonstrates multiple interpolations and whitespace stripping.
@Component(selector: 'attribute', template: '''
    <img alt="\n{{altText}}\n">
    <img alt="\n{{altText}}\n{{altText}}\n">''')
class Attribute {
  var altText = 'Text';
}

// Demonstrates multiple interpolations and whitespace preservation.
@Component(selector: 'attribute', preserveWhitespace: true, template: '''
    <img alt="\n{{altText}}\n">
    <img alt="\n{{altText}}\n{{altText}}\n">''')
class AttributePW {
  var altText = 'Text';
}
