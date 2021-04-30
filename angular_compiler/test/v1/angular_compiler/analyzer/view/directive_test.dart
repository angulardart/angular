import 'package:test/test.dart';
import 'package:angular_compiler/v1/angular_compiler.dart';

import '../../src/compile.dart';

void main() {
  Future<void> expectBuildError(String source, Object matcherOrString) {
    return compilesExpecting(source, (library) async {
      final visitDirective = const DirectiveVisitor().visitDirective;
      library.definingCompilationUnit.types.forEach(visitDirective);
    }, errors: [matcherOrString]);
  }

  test('should catch a @HostBinding on a private member', () async {
    await expectBuildError(
      '''
      class Comp {
        @HostBinding('attr.title')
        var _cantTouchThis;
      }
    ''',
      allOf(
        contains('@HostBinding must be on a public member'),
        contains('_cantTouchThis'),
      ),
    );
  });

  test('should catch a @HostListener on a private member', () async {
    await expectBuildError(
      '''
      class Comp {
        @HostListener('click')
        void _cantTouchThis() {}
      }
    ''',
      allOf(
        contains('@HostListener must be on a public member'),
        contains('_cantTouchThis'),
      ),
    );
  });

  test('should catch a @HostListener on a static method', () async {
    await expectBuildError(
      '''
      class Comp {
        @HostListener('click')
        static void onClick() {}
      }
    ''',
      allOf(
        contains('@HostListener must be on a non-static member'),
        contains('onClick'),
      ),
    );
  });
}
