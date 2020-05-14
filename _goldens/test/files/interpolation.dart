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

@Component(
  selector: 'interpolation',
  template: r'''
    <div>{{foo}}</div>
  ''',
)
class InterpolationNumber {
  int foo = 3;
}

@Component(
  selector: 'interpolation',
  template: r'''
    <div>{{foo}}</div>
  ''',
)
class InterpolationBoolean {
  bool foo = false;
}

@Component(
  selector: 'interpolation',
  template: r'''
    <div>{{foo}}</div>
  ''',
)
class InterpolationConst {
  static const foo = 3;
}

@Component(
  selector: 'interpolation',
  template: r'''
    <div>{{foo()}}</div>
  ''',
)
class InterpolationMethod {
  bool foo() => true;
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

@Component(
  selector: 'interpolation',
  template: r'''
    <div>{{state?.count}}</div>
  ''',
)
class InterpolationProperty {
  State state;
}

class State {
  int count;
  State(this.count);
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

// Demonstates non String primitive interpolation.
@Component(
  selector: 'attribute',
  template: '''
    <img alt="{{altText}}">''',
)
class AttributePrimitive {
  int altText = 0;
}

// Demonstates non String primitive interpolation with prefix or suffix.
@Component(
  selector: 'attribute',
  template: '''
    <img alt="Pre{{altText}}Suf">''',
)
class AttributePrimitiveWithStrings {
  int altText = 0;
}

@Component(
  selector: 'attribute',
  template: r'''
    <div attr.aria-selected="{{isSelected()}}">Hello World</div>
  ''',
)
class AttributeMethod {
  bool isSelected() => true;
}

@Component(
  selector: 'interpolation',
  template: r'''
    <div class="pre{{theme}}"></div>
  ''',
)
class ClassString {
  String theme = 'Theme';
}

@Component(
  selector: 'interpolation',
  template: r'''
    <div style="width:{{width}}px"></div>
  ''',
)
class StyleString {
  String width = '100';
}

@Component(
  selector: 'interpolation',
  template: r'''
    <div style="width:{{width}}px"></div>
  ''',
)
class StyleFinalPrimitive {
  final width = 100;
}

@Component(
  selector: 'interpolation',
  template: r'''
    <div style="width:{{getWidth()}}px"></div>
  ''',
)
class StylePrimitive {
  int getWidth() => 100;
}
