import 'package:angular/angular.dart';

@Component(
  selector: 'test-bar',
  template: '<div>Bar</div>',
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class TestSubComponent {}
