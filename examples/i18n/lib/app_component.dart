import 'dart:html';

import 'package:angular/angular.dart';
import 'package:intl/intl.dart';

/// Defines common messages to be reused across an application.
abstract class Messages {
  static final add = Intl.message('Add',
      desc: 'Text on button that adds an item to the grocery list.');
}

@Component(
  selector: 'app',
  templateUrl: 'app_component.html',
  directives: [NgFor],
  exports: [Messages],
)
class AppComponent {
  final items = <String>[];

  @ViewChild('input')
  InputElement input;

  void add() {
    items.add(input.value);
    input.value = '';
  }
}
