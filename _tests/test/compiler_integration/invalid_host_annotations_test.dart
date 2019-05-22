@TestOn('vm')
import 'package:_tests/compiler.dart';
import 'package:test/test.dart';

void main() {
  group('should fail on @HostBinding', () {
    test('on a method', () {
      return compilesExpecting("""
        import '$ngImport';

        @Component(
          selector: 'bad',
          template: '',
        )
        class BadComp {
          @HostBinding('attr.notAGetter')
          String methodNotValid() => '...';
        }
      """, errors: [
        contains('@HostBinding must be on a field or getter'),
      ]);
    });

    test('on a setter', () {
      return compilesExpecting("""
        import '$ngImport';

        @Component(
          selector: 'bad',
          template: '',
        )
        class BadComp {
          @HostBinding('attr.notAGetter')
          set setterNotValid(_) {}
        }
      """, errors: [
        contains('@HostBinding must be on a field or getter'),
      ]);
    });
  });

  group('should fail on @HostListener', () {
    test('on a getter', () {
      return compilesExpecting("""
        import '$ngImport';

        @Component(
          selector: 'bad',
          template: '',
        )
        class BadComp {
          @HostListener('click')
          String get onClick => '';
        }
      """, errors: [
        contains('@HostListener must be on a method'),
      ]);
    });

    test('on a setter', () {
      return compilesExpecting("""
        import '$ngImport';

        @Component(
          selector: 'bad',
          template: '',
        )
        class BadComp {
          @HostListener('click')
          set onClick(_) {}
        }
      """, errors: [
        contains('@HostListener must be on a method'),
      ]);
    });

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
