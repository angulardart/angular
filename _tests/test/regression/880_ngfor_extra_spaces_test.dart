@TestOn('browser')
import 'package:angular/angular.dart';
import 'package:angular_test/angular_test.dart';
import 'package:test/test.dart';

import '880_ngfor_extra_spaces_test.template.dart' as ng;

// See https://github.com/dart-lang/angular/issues/880.
void main() {
  tearDown(disposeAnyRunningTest);

  test('should ignore extra spaces after a let assignment', () async {
    final fixture = await NgTestBed.forComponent(
      ng.LetAssignmentSpacingTestNgFactory,
    ).create();
    expect(fixture.text, '012');
  });
}

@Component(
  selector: 'let-assignment-spacing-test',
  directives: [NgFor],
  template: r'''
    <ng-container *ngFor="let item of items; let i = index ">
      {{i}}
    </ng-container>
  ''',
)
class LetAssignmentSpacingTest {
  final items = [1, 2, 3];
}
