import 'package:angular/angular.dart';
import 'package:angular_forms/angular_forms.dart';

/// Sample component used to test code generation for @deferred components.
@Component(
  selector: 'my-deferred-input',
  directives: [formDirectives, NgIf],
  template: r'''
    <template [ngIf]="inputEnabled">
      <input [(ngModel)]="model"> {{ model }}
    </template>
  ''',
)
class DeferredInputComponent {
  String model = 'initial text';
  bool inputEnabled = true;
}
