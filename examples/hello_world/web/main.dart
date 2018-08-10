import 'package:angular/angular.dart';

import 'main.template.dart' as ng;

void main() => runApp(ng.HelloWorldComponentNgFactory);

@Component(
  selector: 'hello-world',
  directives: [
    NgIf,
    BugComponent,
  ],
  template: r'''
    <button (click)="showOuter = !showOuter">Toggle</button>
    <template [ngIf]="showOuter">
      <i-am-buggy @deferred></i-am-buggy>
    </template>
    
    <div>
      <button (click)="showOuter2 = !showOuter2">Toggle</button>
      <template [ngIf]="showOuter2">
        <template [ngIf]="showInner">
          <i-am-buggy></i-am-buggy>
        </template>
      </template>
    </div>
  ''',
)
class HelloWorldComponent {
  bool showOuter = false;
  bool showOuter2 = false;
  bool showInner = true;
}

@Component(
  selector: 'i-am-buggy',
  template: 'BUG BUG BUG',
)
class BugComponent {}
