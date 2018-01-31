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
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class EmptyPropertiesComponent {}

@Component(
  selector: 'fancy-button',
  template: '',
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class FancyButtonComponent {
  @Input()
  bool raised = false;
}
