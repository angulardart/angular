@TestOn('browser')
import 'dart:async';

import 'package:test/test.dart';
import 'package:angular/angular.dart';
import 'package:angular_test/angular_test.dart';
import 'package:angular_test/src/errors/will_never_stabilize.dart';

import 'stabilizer_test.template.dart' as template;

void main() {
  test('should throw error when stabilization threshold is exceeded', () async {
    final testBed =
        NgTestBed.forComponent(template.WillNeverStabilizeComponentNgFactory);
    expect(testBed.create, throwsA(TypeMatcher<WillNeverStabilizeError>()));
  }, skip: 'b/140626607');
}

@Component(
  selector: 'test',
  template: '',
)
class WillNeverStabilizeComponent implements DoCheck {
  @override
  void ngDoCheck() {
    // This creates an infinite change detection loop.
    scheduleMicrotask(() {});
  }
}
