import 'package:test/test.dart';
import 'package:angular_compiler/v1/angular_compiler.dart';
import 'package:angular_compiler/v2/context.dart';

import '../src/resolve.dart';

void main() {
  CompileContext.overrideForTesting();

  test('should record a no-op', () async {
    final testLib = await resolveLibrary('');
    final output = await ReflectableReader.noLinking().resolve(testLib);
    expect(
      output,
      ReflectableOutput(),
    );
  });

  test('should record a factory', () async {
    final testLib = await resolveLibrary(r'''
      @Injectable()
      Duration getDuration(DateTime date) => null;

      Duration notAnnotated() => null;
    ''');
    final output = await ReflectableReader.noLinking().resolve(testLib);
    expect(
      output,
      ReflectableOutput(
        registerFunctions: [
          DependencyInvocation(
            testLib.definingCompilationUnit.functions.firstWhere(
              (e) => e.name == 'getDuration',
            ),
            [
              DependencyElement(
                TypeTokenElement(
                  const TypeLink('DateTime', 'dart:core'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  });

  test('should record a class', () async {
    final testLib = await resolveLibrary(r'''
      @Injectable()
      class Example {
        Example(Duration duration);
      }
    ''');
    final output = await ReflectableReader.noLinking().resolve(testLib);
    final clazz = testLib.definingCompilationUnit.types.first;
    expect(
      output,
      ReflectableOutput(registerClasses: [
        ReflectableClass(
          element: clazz,
          name: 'Example',
          factory: DependencyInvocation(
            clazz.unnamedConstructor,
            [
              DependencyElement(
                TypeTokenElement(
                  const TypeLink('Duration', 'dart:core'),
                ),
              ),
            ],
          ),
        ),
      ]),
    );
  });

  group('for linking', () {
    late Set<String> _fakeInputs;
    late Set<String> _fakeIsLibrary;
    late ReflectableReader reader;

    setUp(() {
      _fakeInputs = <String>{};
      _fakeIsLibrary = <String>{};
      reader = ReflectableReader(
        hasInput: _fakeInputs.contains,
        isLibrary: (lib) async => _fakeIsLibrary.contains(lib),
      );
    });

    test('should always link to an imported .template.dart', () async {
      final testLib = await resolveLibrary(r'''
        import 'foo.template.dart';
        export 'bar.template.dart';
      ''');
      final output = await reader.resolve(testLib);
      expect(
        output.urlsNeedingInitReflector,
        unorderedEquals([
          'foo.template.dart',
          'bar.template.dart',
        ]),
      );
    });

    test('should link to a file that has a .template.dart on disk', () async {
      _fakeIsLibrary.add('foo.template.dart');
      final testLib = await resolveLibrary(r'''
        import 'foo.dart';
        import 'bar.dart';
      ''');
      final output = await reader.resolve(testLib);
      expect(
        output.urlsNeedingInitReflector,
        [
          'foo.template.dart',
        ],
      );
    });

    test('should link to a file that will have a .template.dart', () async {
      _fakeInputs.add('foo.dart');
      final testLib = await resolveLibrary(r'''
        import 'foo.dart';
        import 'bar.dart';
      ''');
      final output = await reader.resolve(testLib);
      expect(
        output.urlsNeedingInitReflector,
        [
          'foo.template.dart',
        ],
      );
    });
  });

  group('errors', () {
    late ReflectableReader reader;

    var pleaseThrow = 'please.throw';
    setUp(() {
      reader = ReflectableReader(
        hasInput: (input) => input.contains(pleaseThrow)
            ? throw Exception('bad input $input')
            : false,
        isLibrary: (lib) async => lib.contains(pleaseThrow)
            ? throw Exception('bad library $lib')
            : false,
      );
    });

    test('should throw on invalid asset it', () async {
      final testLib = await resolveLibrary('''
        import 'package:$pleaseThrow/file.dart';
      ''');
      expect(
        reader.resolve(testLib),
        throwsA(
          TypeMatcher<BuildError>().having(
            (e) => e.toString(),
            'toString()',
            allOf(
              contains('Could not parse URI'),
              contains('line 4, column 9'),
            ),
          ),
        ),
      );
    });

    test('should throw on private injectable class', () async {
      final testLib = await resolveLibrary(r'''
        @Injectable()
        class _Example {
          Example(Duration duration);
        }
      ''');
      expect(
        reader.resolve(testLib),
        throwsA(
          TypeMatcher<BuildError>().having(
            (e) => e.toString(),
            'toString()',
            allOf(
              contains('Private classes can not be @Injectable'),
              contains('line 5, column 15'),
            ),
          ),
        ),
      );
    });
  });
}
