import 'package:angular/angular.dart';

@Component(
  selector: 'deferred-component', template: '<div>Child</div>',
  // TODO(b/65383776): Change preserveWhitespace to false to improve codesize.
  preserveWhitespace: true,
)
class DeferredChildComponent {}
