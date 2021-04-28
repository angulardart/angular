import 'package:build/build.dart';
import 'package:test/test.dart';
import 'package:angular_compiler/v2/testing.dart';

void main() {
  test('should resolve a component', () async {
    final library = await resolve(
      '''
      @Component(
        selector: 'example',
        template: 'Hello World',
      )
      class Example {}
      ''',
    );
    expect(
      library
          .getType('Example')!
          .metadata
          .first
          .computeConstantValue()!
          .getField('template')!
          .toStringValue(),
      'Hello World',
    );
  });

  test('should fail to resolve a component', () async {
    final library = await resolve(
      '''
      @Component(
        selector: 'example',
        template: 'Hello World',
      )
      class Example {}
      ''',
      includeAngularDeps: false,
    );
    expect(
      library.getType('Example')!.metadata.first.computeConstantValue(),
      isNull,
      reason: 'Angular was not loaded',
    );
  });

  test('should resolve code in another file', () async {
    final library = await resolve(
      '''
        import 'another.dart';
        @Component(
          selector: 'example',
          template: 'Hello World',
        )
        class Example extends Base {}
      ''',
      additionalFiles: {
        AssetId('test_lib', 'lib/another.dart'): 'class Base {}'
      },
    );
    final clazz = library.getType('Example')!;
    expect(
      clazz.metadata.first
          .computeConstantValue()!
          .getField('template')!
          .toStringValue(),
      'Hello World',
    );
    expect(clazz.supertype!.element.name, 'Base');
  });
}
