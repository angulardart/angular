import 'package:analyzer/dart/element/element.dart';
import 'package:angular_compiler/angular_compiler.dart';
import 'package:test/test.dart';

import '../../src/resolve.dart';

void main() {
  LibraryElement testLib;

  setUpAll(() async {
    testLib = await resolveLibrary(r'''
      @Component(
        providers: const [
          const Provider(ExampleService),
        ],
      )
      class CompWithProvider {}

      @Component(
        viewProviders: const [
          const Provider(ExampleService),
        ],
      )
      class CompWithViewProvider {}

      @Injectable()
      class ExampleService {}
    ''');
  });

  ClassElement getClass(String name) => testLib.getType(name);

  test('should resolve a provider', () {
    final component = new ComponentReader(getClass('CompWithProvider'));
    expect(
      component.provides(new TypeTokenElement(Uri.parse(
        'asset:test_lib/lib/test_lib.dart#ExampleService',
      ))),
      isTrue,
      reason: '"ExampleService" should be provided by the component.',
    );
  });

  test('should resolve a view provider', () {
    final component = new ComponentReader(getClass('CompWithViewProvider'));
    expect(
      component.provides(new TypeTokenElement(Uri.parse(
        'asset:test_lib/lib/test_lib.dart#ExampleService',
      ))),
      isTrue,
      reason: '"ExampleService" should be provided by the component',
    );
    expect(
      component.providesForContent(new TypeTokenElement(Uri.parse(
        'asset:test_lib/lib/test_lib.dart#ExampleService',
      ))),
      isFalse,
      reason: '"ExampleService" should not be visible to <ng-content>.',
    );
  });
}
