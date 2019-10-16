import 'dart:async';

import 'package:angular_compiler/angular_compiler.dart';
import 'package:test/test.dart';

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

  test('should catch a @HostBinding on a non-getter', () async {
    await expectBuildError(
      '''
      class Comp {
        @HostBinding('attr.title')
        void cantBindThis() {}
      }
    ''',
      allOf(
        contains('@HostBinding must be on a field or getter'),
        contains('cantBindThis'),
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

  test('should catch a @HostListener on a non-method', () async {
    await expectBuildError(
      '''
      class Comp {
        @HostListener('click')
        Function fn;
      }
    ''',
      allOf(
        contains('@HostListener must be on a method'),
        contains('fn'),
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
