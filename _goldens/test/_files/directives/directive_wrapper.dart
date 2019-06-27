import 'dart:async';
import 'dart:html';
import 'package:angular/angular.dart';

@Directive(
  selector: '[some-child-directive]',
)
class ChildDirective implements OnInit, OnDestroy, AfterChanges {
  Element element;

  // ignore: deprecated_member_use
  ElementRef elementRef;

  ChildDirective(this.element, this.elementRef);

  StreamController _triggerController;

  @Input()
  set input1WithString(String s) {}

  @Input()
  set inputWithIterable(Iterable<int> intList) {}

  @Input('row')
  set gridRow(int value) {
    print(value);
  }

  @Output()
  Stream get trigger {
    _triggerController ??= StreamController.broadcast();
    return _triggerController.stream;
  }

  @HostListener('click')
  void handleClick(e) {}

  @HostListener('keypress')
  void handleKeyPress(e) {}

  @HostListener('eventXyz')
  void handleXyzEventFromOtherDirective(e) {}

  @HostBinding('tabindex')
  int get tabIndex => -1;

  @HostBinding('attr.role')
  static const hostRole = 'button';

  @HostBinding('attr.aria-label')
  final label = 'Directive';

  @HostBinding('attr.aria-disabled')
  String get disabledStr => '';

  @HostBinding('class.is-disabled')
  bool get disabled => false;

  @override
  void ngOnInit() {}

  @override
  void ngOnDestroy() {}

  @override
  void ngAfterChanges() {}
}

@Directive(
  selector: '[directive-with-output]',
)
class DirectiveWithOutput {
  String msg;
  final _streamController = StreamController<String>();

  @Output()
  Stream get eventXyz => _streamController.stream;

  fireEvent(String msg) {
    _streamController.add(msg);
  }
}

@Component(
  selector: 'test-foo',
  template: r'''
    <div some-child-directive
         directive-with-output
         [row]="rowIndex"
         (trigger)="onTrigger">
      Foo
    </div>
  ''',
  directives: [ChildDirective, DirectiveWithOutput],
  styles: ['div { font-size: 10px; }'],
)
class TestFooComponent {
  int get rowIndex => 5;
  void onTrigger(e) {}
}

@Injectable()
class MyInjectableClass {
  String get title => 'hello';
}
