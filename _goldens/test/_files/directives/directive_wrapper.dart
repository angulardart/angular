import 'dart:async';
import 'dart:html';
import 'package:angular/angular.dart';
import 'package:angular_forms/angular_forms.dart';

@Directive(
  selector: '[some-child-directive]',
  host: const {
    '(click)': r'handleClick($event)',
    '(keypress)': r'handleKeyPress($event)',
    '(eventXyz)': r'handleXyzEventFromOtherDirective($event)',
    '[tabindex]': 'tabIndex',
    'role': 'button',
    '[attr.aria-disabled]': 'disabledStr',
    '[class.is-disabled]': 'disabled',
  },
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class ChildDirective {
  Element element;
  ElementRef elementRef;
  ChildDirective(this.element, this.elementRef);

  StreamController _triggerController;

  @Input()
  set input1WithString(String s) {}

  @Input()
  set inputWithIterable(Iterable<int> intList) {}

  @Input('row')
  set gridRow(String value) {
    print(value);
  }

  @Output()
  Stream get trigger {
    _triggerController ??= new StreamController.broadcast();
    return _triggerController.stream;
  }

  void handleClick(e) {}
  void handleKeyPress(e) {}
  void handleXyzEventFromOtherDirective(e) {}
  int get tabIndex => -1;
  String get disabledStr => '';
  bool get disabled => false;
}

@Directive(
  selector: '[directive-with-output]',
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class DirectiveWithOutput {
  String msg;
  final _streamController = new StreamController<String>();

  @Output()
  Stream get eventXyz => _streamController.stream;

  fireEvent(String msg) {
    _streamController.add(msg);
  }
}

@Component(
  selector: 'test-foo',
  template:
      '<div some-child-directive directive-with-output [row]="rowIndex" (trigger)="onTrigger">Foo</div>',
  directives: const [ChildDirective, DirectiveWithOutput],
  styles: const ['div { font-size: 10px; }'],
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class TestFooComponent {
  int get rowIndex => 5;
  void onTrigger(e) {}
}

@Injectable()
class MyInjectableClass {
  String get title => 'hello';
}

@Component(
  selector: 'input-form-test',
  directives: const [formDirectives],
  template: '''
<div [ngFormModel]="form">
  <input type="text" ngControl="login">
</div>''',
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class InputFormTest {
  ControlGroup form;
}

@Directive(
  host: const {'[attr.data-msg]': 'msg'},
  selector: '[fastDirective]',
)
class FastDirective extends ComponentState {
  Element element;
  String msg;
  String _prevValue;

  FastDirective(this.element);

  @Input()
  set name(String value) {
    if (_prevValue == value) return;
    _prevValue = value;
    setState(() => msg = 'Hello $value');
  }
}

@Component(
  selector: 'directive-container',
  template: r'<div class="target1" fastDirective [name]="finalName"></div>'
      '<div class="target2" fastDirective [name]="nonFinal"></div>',
  directives: const [FastDirective],
)
class DirectiveContainerTest {
  final String finalName = "xyz";
  String nonFinal = "abc";
}
