import 'package:angular/angular.dart';

@Component(
  selector: 'empty-properties',
  template: '''
<fancy-button raised></fancy-button>
<fancy-button [raised]></fancy-button>
<fancy-button [raised]="true"></fancy-button>
<fancy-button [raised]="false"></fancy-button>
''',
  directives: const [FancyButtonComponent],
)
class EmptyPropertiesComponent {}

@Component(selector: 'fancy-button', template: '')
class FancyButtonComponent {
  @Input()
  bool raised = false;
}
