@TestOn('vm')
import 'package:_tests/compiler.dart';
import 'package:test/test.dart';

void main() {
  test('should warn that OnPush children should also be OnPush', () async {
    await compilesExpecting("""
      import '$ngImport';

      @Component(
        selector: 'default',
        template: '',
      )
      class DefaultChild {}

      @Component(
        selector: 'on-push',
        template: '''
          <div>
            <default></default>
          </div>
        ''',
        changeDetection: ChangeDetectionStrategy.OnPush,
        directives: [DefaultChild],
      )
      class OnPushParent {}
    """, warnings: [
      allOf([
        containsSourceLocation(2, 13),
        contains('<default>'),
        contains(
            '"DefaultChild" doesn\'t use "ChangeDetectionStrategy.OnPush"'),
      ]),
    ]);
  });
}
