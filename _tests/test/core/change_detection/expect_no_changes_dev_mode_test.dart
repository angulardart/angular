@TestOn('browser')
import 'package:angular_test/angular_test.dart';
import 'package:test/test.dart';
import 'package:angular/angular.dart';

import 'expect_no_changes_dev_mode_test.template.dart' as ng_generated;

void main() {
  ng_generated.initReflector();

  test('should throw during change detection', () async {
    final testBed = new NgTestBed<IllegalChangeDetectionComponent>();
    expect(
      testBed.create(),
      throwsA(predicate(
        (e) => '$e'.contains('Expression has changed after it was checked'),
      )),
    );
  });
}

@Component(
  selector: 'illegal-change-detection',
  template: r'''
    <div>{{counter}}</div>
  ''',
)
class IllegalChangeDetectionComponent {
  var _counter = 0;
  int get counter => _counter++;
}
