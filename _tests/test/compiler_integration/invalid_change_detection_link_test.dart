@TestOn('vm')
import 'package:_tests/compiler.dart';
import 'package:test/test.dart';

// TODO(b/119571379): import angular/experimental.dart
const ngChangeDetectionLinkImport =
    'package:$ngPackage/src/core/metadata/change_detection_link.dart';

void main() {
  group('@changeDetectionLink', () {
    test('should compile on OnPush component', () async {
      await compilesNormally("""
        import '$ngImport';
        import '$ngChangeDetectionLinkImport';

        @changeDetectionLink
        @Component(
          selector: 'test',
          template: '',
          changeDetection: ChangeDetectionStrategy.OnPush,
        )
        class OnPushComponent {}
      """);
    });

    test("shouldn't compile on CheckAlways component", () async {
      await compilesExpecting("""
        import '$ngImport';
        import '$ngChangeDetectionLinkImport';

        @changeDetectionLink
        @Component(
          selector: 'test',
          template: '',
        )
        class CheckAlwaysComponent {}
      """, errors: [
        allOf([
          contains(
            'Only supported on components that use "OnPush" change detection',
          ),
          containsSourceLocation(4, 9),
        ]),
      ]);
    });

    test("shouldn't compile on directive", () async {
      await compilesExpecting("""
        import '$ngImport';
        import '$ngChangeDetectionLinkImport';

        @changeDetectionLink
        @Directive(selector: '[test]')
        class TestDirective {}
      """, errors: [
        allOf([
          contains(
            'Only supported on components that use "OnPush" change detection',
          ),
          containsSourceLocation(4, 9),
        ]),
      ]);
    });
  });
}
