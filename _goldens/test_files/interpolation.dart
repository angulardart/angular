import 'package:angular/angular.dart';

@Component(
  selector: 'interpolation',
  template: '''
<div>
  {{foo}}
</div>
''',
  // TODO(b/65383776): Change preserveWhitespace to false to improve codesize.
  preserveWhitespace: true,
)
class InterpolationComponent {
  String foo = 'hello';
}

@Component(
  selector: 'interpolation',
  template: '''
<div>
  {{foo}}
</div>
''',
  preserveWhitespace: false,
)
class InterpolationComponentNoWhitespace {
  String foo = 'hello';
}
