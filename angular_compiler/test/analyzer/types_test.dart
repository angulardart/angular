import 'package:analyzer/dart/element/element.dart';
import 'package:angular_compiler/angular_compiler.dart';
import 'package:test/test.dart';

import '../src/resolve.dart';

void main() {
  group('should resolve', () {
    LibraryElement testLib;

    setUpAll(() async {
      testLib = await resolveLibrary(r'''
        @Directive()
        class ADirective {}

        @Component()
        class AComponent {}

        @Injectable()
        class AnInjectable {}

        void hasInject(@Inject(#dep) List dep) {}

        void hasOptional(@Optional() List dep) {}

        void hasSelf(@Self() List dep) {}

        void hasSkipSelf(@SkipSelf() List dep) {}

        void hasHost(@Host() List dep) {}
      ''');
    });

    test('@Directive', () {
      final aDirective = testLib.getType('ADirective');
      expect($Directive.firstAnnotationOfExact(aDirective), isNotNull);
    });

    test('@Component', () {
      final aComponent = testLib.getType('AComponent');
      expect($Component.firstAnnotationOfExact(aComponent), isNotNull);
    });

    test('@Injectable', () {
      final anInjectable = testLib.getType('AnInjectable');
      expect($Injectable.firstAnnotationOfExact(anInjectable), isNotNull);
    });

    group('injection annotations', () {
      Element getParameterFrom(String name) =>
          testLib.definingCompilationUnit.functions
              .firstWhere((e) => e.name == name)
              .parameters
              .first;

      const {
        'hasHost': $Host,
        'hasInject': $Inject,
        'hasOptional': $Optional,
        'hasSelf': $Self,
        'hasSkipSelf': $SkipSelf,
      }.forEach((name, type) {
        test('of $type should find "$name"', () {
          final parameter = getParameterFrom(name);
          expect(type.firstAnnotationOfExact(parameter), isNotNull);
        });
      });
    });
  });
}
