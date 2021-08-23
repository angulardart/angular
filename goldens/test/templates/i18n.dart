import 'package:angular/angular.dart';

import 'i18n.template.dart' as ng;

void main() {
  runApp(ng.createGoldenComponentFactory());
}

@Component(
  selector: 'golden',
  directives: [
    MessageDirective,
  ],
  template: '''
    <!-- Text -->
    <p
      @i18n="description"
      @i18n.locale="en_US"
      @i18n.meaning="meaning"
      @i18n.skip
    >
      Message
    </p>

    <!-- Attribute -->
    <img alt="message" @i18n:alt="description">

    <!-- HTML -->
    <p @i18n="description">
      This message<br>
      contains <i>multiple levels of <b>nested</b> HTML</i>.
    </p>

    <!-- Property -->
    <div [message]="'message'" @i18n:message="description"></div>
  ''',
)
class GoldenComponent {}

@Directive(
  selector: '[message]',
)
class MessageDirective {
  @Input()
  String? message;
}
