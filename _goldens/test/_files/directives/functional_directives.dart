import 'dart:html';

import 'package:angular/angular.dart';

@Injectable()
class TextService {
  String generateText() => 'text';
}

@Directive(selector: '[generateText]')
void generateTextDirective(HtmlElement element, TextService textService) {
  element.text = textService.generateText();
}

@Component(
  selector: 'app',
  template: '<div generateText><div></div></div>',
  directives: [generateTextDirective],
  providers: [TextService],
)
class AppComponent {}
