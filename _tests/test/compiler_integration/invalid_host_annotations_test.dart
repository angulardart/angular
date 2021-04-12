// @dart=2.9

import 'package:test/test.dart';
import 'package:_tests/compiler.dart';
import 'package:angular_compiler/v2/context.dart';

void main() {
  CompileContext.overrideForTesting();

  group('should fail on @HostBinding', () {
    test('Invalid value with dot symbol prefix', () {
      return compilesExpecting("""
        import '$ngImport';

        @Component(
          selector: 'bad',
          template: '',
        )
        class BadComp {
          @HostBinding('.foo')
          final foo = true;
        }
      """, errors: [
        contains("Invalid property name '.foo'"),
      ]);
    });
  });

  group('should fail on @HostListener', () {
    test('on a static method', () {
      return compilesExpecting("""
        import '$ngImport';

        @Component(
          selector: 'bad',
          template: '',
        )
        class BadComp {
          @HostListener('click')
          static void onClick() {}
        }
      """, errors: [
        contains('@HostListener must be on a non-static member'),
      ]);
    });

    test('on a method where required arguments > 1 and not specified', () {
      return compilesExpecting("""
        import '$ngImport';

        @Component(
          selector: 'bad',
          template: '',
        )
        class BadComp {
          @HostListener('click')
          void onClick(arg1, arg2) {}
        }
      """, errors: [
        contains('@HostListener is only valid on methods with 0 or 1'),
      ]);
    }, skip: 'b/133248314');

    test('on a method where specified arguments > number of arguments', () {
      return compilesExpecting("""
        import '$ngImport';

        @Component(
          selector: 'bad',
          template: '',
        )
        class BadComp {
          @HostListener('click', const [r'\$event'])
          void onClick() {}
        }
      """, errors: [
        contains('@HostListener expected a method with 1 parameter(s)'),
      ]);
    });
  });
}
