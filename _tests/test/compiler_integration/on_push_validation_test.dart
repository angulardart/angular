// @dart=2.9

import 'package:test/test.dart';
import 'package:_tests/compiler.dart';
import 'package:angular_compiler/v2/context.dart';

void main() {
  CompileContext.overrideForTesting();

  test('emits warning for Default component in OnPush template', () async {
    await compilesExpecting("""
      import '$ngImport';

      @Component(
        selector: 'default',
        template: '',
      )
      class DefaultComponent {}

      @Component(
        selector: 'test',
        template: '''
          <div>
            <default></default>
          </div>
        ''',
        changeDetection: ChangeDetectionStrategy.OnPush,
        directives: [DefaultComponent],
      )
      class TestComponent {}
    """, warnings: [
      allOf([
        contains('<default>'),
        contains(
          '"DefaultComponent" doesn\'t use "ChangeDetectionStrategy.OnPush"',
        ),
      ]),
    ]);
  });

  group('@skipOnPushValidation', () {
    test('silences warning for Default component in OnPush template', () async {
      await compilesNormally("""
        import '$ngImport';

        @Component(
          selector: 'default',
          template: '',
        )
        class DefaultComponent {}

        @Component(
          selector: 'test',
          template: '''
            <div>
              <default @skipOnPushValidation></default>
            </div>
          ''',
          changeDetection: ChangeDetectionStrategy.OnPush,
          directives: [DefaultComponent],
        )
        class TestComponent {}
      """);
    });

    group('is not permitted', () {
      test('on an HTML element', () async {
        await compilesExpecting("""
          import '$ngImport';

          @Component(
            selector: 'test',
            template: '''
              <div @skipOnPushValidation></div>
            ''',
            changeDetection: ChangeDetectionStrategy.OnPush,
          )
          class TestComponent {}
        """, errors: [
          allOf([
            contains('@skipOnPushValidation'),
            contains('Can only be applied to a component element'),
          ]),
        ]);
      });

      test('on an OnPush component', () async {
        await compilesExpecting("""
          import '$ngImport';

          @Component(
            selector: 'on-push',
            template: '',
            changeDetection: ChangeDetectionStrategy.OnPush,
          )
          class OnPushComponent {}

          @Component(
            selector: 'test',
            template: '''
              <on-push @skipOnPushValidation></on-push>
            ''',
            directives: [OnPushComponent],
            changeDetection: ChangeDetectionStrategy.OnPush,
          )
          class TestComponent {}
        """, errors: [
          allOf([
            contains('@skipOnPushValidation'),
            contains(
              'Can only be applied to a component using '
              '"ChangeDetectionStrategy.Default"',
            ),
          ]),
        ]);
      });

      test('in the template of a Default component', () async {
        await compilesExpecting("""
          import '$ngImport';

          @Component(
            selector: 'default',
            template: '',
          )
          class DefaultComponent {}

          @Component(
            selector: 'test',
            template: '''
              <default @skipOnPushValidation></default>
            ''',
            directives: [DefaultComponent],
          )
          class TestComponent {}
        """, errors: [
          allOf([
            contains('@skipOnPushValidation'),
            contains(
              'Can only be used in the template of a component using '
              '"ChangeDetectionStrategy.OnPush"',
            ),
          ]),
        ]);
      });
    });
  });
}
