import 'package:angular/angular.dart';

@Component(
  selector: 'interpolation',
  template: '''
<div>
  {{foo}}
</div>
''',
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
