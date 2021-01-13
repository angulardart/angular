@JS()
library golden;

import 'package:js/js.dart';
import 'package:angular/angular.dart';

import 'after_queries.template.dart' as ng;

/// Avoids Dart2JS thinking something is constant/unchanging.
@JS()
external T deopt<T>([Object? any]);

void main() {
  runApp(ng.createGoldenComponentFactory());
}

@Component(
  selector: 'golden',
  directives: [
    NgIf,
    UsesAfterContent,
    UsesAfterView,
    ChildComponent,
  ],
  template: '''
    <uses-after-view></uses-after-view>
    <uses-after-content>
      <!-- Static -->
      <child [value]="value"></child>
      <!-- Dynamic -->
      <child *ngIf="showValue" [value]="value"></child>
    </uses-after-content>
  ''',
)
class GoldenComponent {
  GoldenComponent() {
    deopt(() {
      value = deopt('value');
    });
  }

  late String value;

  bool showValue = deopt();
}

@Component(
  selector: 'uses-after-view',
  directives: [
    ChildComponent,
    NgIf,
  ],
  template: '''
    <!-- Static -->
    <child [value]="value"></child>
    <!-- Dynamic -->
    <child *ngIf="showValue" [value]="value"></child>
  ''',
)
class UsesAfterView implements AfterViewInit, AfterViewChecked {
  UsesAfterView() {
    deopt(() {
      value = deopt('value');
    });
  }

  late String value;

  bool showValue = deopt();

  @override
  void ngAfterViewInit() {
    deopt('ngAfterViewInit');
  }

  @override
  void ngAfterViewChecked() {
    deopt('ngAfterViewChecked');
  }
}

@Component(
  selector: 'child',
  template: '',
)
class ChildComponent {
  @Input()
  set value(Object value) {
    deopt(value);
  }
}

@Component(
  selector: 'uses-after-content',
  template: '<ng-content></ng-content>',
)
class UsesAfterContent implements AfterContentInit, AfterContentChecked {
  @override
  void ngAfterContentInit() {
    deopt('ngAfterContentInit');
  }

  @override
  void ngAfterContentChecked() {
    deopt('ngAfterContentChecked');
  }
}
