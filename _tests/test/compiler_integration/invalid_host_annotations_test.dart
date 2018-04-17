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
        contains('@HostBinding must be used on a getter or field'),
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
        contains('@HostBinding must be used on a getter or field'),
      ]);
    });
  }, skip: 'Not yet supported');

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
        contains('@HostListener must be used on an instance method'),
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
        contains('@HostListener must be used on an instance method'),
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
        contains('@HostListener must be used on an instance method'),
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
        contains('@HostListener can only infer a single argument, but 2 found'),
      ]);
    });

    test('on a method where specified arguments > number of arguments', () {
      return compilesExpecting("""
        import '$ngImport';

        @Component(
          selector: 'bad',
          template: '',
        )
        class BadComp {
          @HostListener('click', const [r'\$event', r'\$event'])
          void onClick(arg1) {}
        }
      """, errors: [
        contains('@HostListener expected 2 arguments, but 1 found'),
      ]);
    });
  }, skip: 'Not yet supported');
}
