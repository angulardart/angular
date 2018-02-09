import 'package:angular/angular.dart';

/// This exists entirely to be imported and used by code in `test_files/`.
@Component(
  selector: 'sample-component',
  template: '',
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class SampleComponent {}
