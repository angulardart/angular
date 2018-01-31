import 'package:angular/angular.dart';

@Component(
  selector: 'interpolation',
  template: '''
<div>
  {{foo}}
</div>
''',
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
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
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class InterpolationComponentNoWhitespace {
  String foo = 'hello';
}
