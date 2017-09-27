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
  // TODO(b/65383776): Change preserveWhitespace to false to improve codesize.
  preserveWhitespace: true,
)
class EmptyPropertiesComponent {}

@Component(
  selector: 'fancy-button', template: '',
  // TODO(b/65383776): Change preserveWhitespace to false to improve codesize.
  preserveWhitespace: true,
)
class FancyButtonComponent {
  @Input()
  bool raised = false;
}
