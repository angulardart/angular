import 'package:angular2/angular2.dart';

/// Sample component used to test generating code for deferred loading of
/// components.
@Component(
    selector: 'my-deferred-view',
    template: '<div id="titleDiv" (click)="doClick()" '
        '[attr.selected]="selected">'
        '{{title}}</div>')
class DeferredChildComponent extends SomeBaseClass {
  bool selected = false;

  @Input()
  set title(String value) {
    titleBase = value;
  }

  String get title => titleBase;

  void doClick() {
    selected = true;
  }
}

class SomeBaseClass {
  String titleBase;
}
