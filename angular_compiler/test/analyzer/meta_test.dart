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
        class AComponent {
          @ContentChildren()
          List<ADirective> contentChildren;

          @ContentChild()
          ADirective contentChild;

          @ViewChildren()
          List<ADirective> viewChildren;

          @ViewChild()
          ADirective viewChild;

          @Input()
          set input(String input) {}

          @Output()
          get output => null;
        }

        @Pipe('aPipe')
        class APipe {}

        @Injectable()
        class AnInjectable {}

        void hasAttribute(@Attribute('name') String name) {}

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

    test('@Pipe', () {
      final aPipe = testLib.getType('APipe');
      expect($Pipe.firstAnnotationOfExact(aPipe), isNotNull);
    });

    test('@Injectable', () {
      final anInjectable = testLib.getType('AnInjectable');
      expect($Injectable.firstAnnotationOfExact(anInjectable), isNotNull);
    });

    group('', () {
      Element getParameterFrom(String name) =>
          testLib.definingCompilationUnit.functions
              .firstWhere((e) => e.name == name)
              .parameters
              .first;

      const {
        'hasAttribute': $Attribute,
        'hasHost': $Host,
        'hasInject': $Inject,
        'hasOptional': $Optional,
        'hasSelf': $Self,
        'hasSkipSelf': $SkipSelf,
      }.forEach((name, type) {
        test('should find $type', () {
          final parameter = getParameterFrom(name);
          expect(type.firstAnnotationOfExact(parameter), isNotNull);
        });
      });
    });

    group('', () {
      Element getInstanceFrom(String name) {
        final type = testLib.getType('AComponent');
        final maybe = type.getField(name);
        return maybe?.metadata?.isNotEmpty == true
            ? maybe
            : type.getGetter(name) ??
                type.getSetter(name) ??
                type.getMethod(name);
      }

      const {
        'contentChildren': $ContentChildren,
        'contentChild': $ContentChild,
        'viewChildren': $ViewChildren,
        'viewChild': $ViewChild,
        'input': $Input,
        'output': $Output,
      }.forEach((name, type) {
        test('should find $type', () {
          final parameter = getInstanceFrom(name);
          expect(type.firstAnnotationOfExact(parameter), isNotNull);
        });
      });
    });
  });
}
