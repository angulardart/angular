import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:test/test.dart';
import 'package:angular_compiler/angular_compiler.dart';

import '../../src/resolve.dart';

void main() {
  group('ModuleReader', () {
    const reader = const ModuleReader();

    ClassElement $Example;
    ClassElement $Dependency;
    DartObject $listModule;
    DartObject $newModuleA;
    DartObject $newModuleB;
    DartObject $newModuleC;

    setUpAll(() async {
      final testLib = await resolveLibrary(r'''
        @listModule
        @newModuleA
        @newModuleB
        @newModuleC
        @Injectable()
        class Example {}

        class ExamplePrime extends Example {}

        class Dependency {}

        const listModule = const [
          Example,
          newModuleA,
        ];

        const newModuleA = const Module(
          provide: const [
            Dependency
          ],
        );

        const newModuleB = const Module(
          include: const [
            newModuleA,
          ],

          provide: const [
            Example,
          ],
        );

        const newModuleC = const Module(
          include: const [
            newModuleB,
          ],

          provide: const [
            const Provider(Example, useClass: ExamplePrime),
          ],
        );
      ''');
      $Example = testLib.getType('Example');
      $Dependency = testLib.getType('Dependency');
      $listModule = $Example.metadata.first.computeConstantValue();
      $newModuleA = $Example.metadata[1].computeConstantValue();
      $newModuleB = $Example.metadata[2].computeConstantValue();
      $newModuleC = $Example.metadata[3].computeConstantValue();
    });

    group('should parse module', () {
      test('from a list (implicit module)', () {
        expect(
          reader.parseModule($listModule),
          new ModuleElement(provide: [
            new UseClassProviderElement(
              new TypeTokenElement(urlOf($Example)),
              urlOf($Example),
              dependencies: new DependencyInvocation(
                $Example.unnamedConstructor,
                const [],
              ),
            )
          ], include: [
            new ModuleElement(
              provide: [
                new UseClassProviderElement(
                  new TypeTokenElement(urlOf($Dependency)),
                  urlOf($Dependency),
                  dependencies: new DependencyInvocation(
                    $Dependency.unnamedConstructor,
                    const [],
                  ),
                )
              ],
              include: [],
            )
          ]),
        );
      });

      group('using the new "Module" syntax', () {
        test('with just "provide"', () {
          expect(
            reader.parseModule($newModuleA),
            new ModuleElement(
              provide: [
                new UseClassProviderElement(
                  new TypeTokenElement(urlOf($Dependency)),
                  urlOf($Dependency),
                  dependencies: new DependencyInvocation(
                    $Dependency.unnamedConstructor,
                    const [],
                  ),
                )
              ],
              include: [],
            ),
          );
        });

        test('with both "provide" and "include"', () {
          final module = reader.parseModule($newModuleB);

          // Purposefully not de-duplicated, tooling might want to know.
          expect(
            module,
            new ModuleElement(
              provide: [
                new UseClassProviderElement(
                  new TypeTokenElement(urlOf($Example)),
                  urlOf($Example),
                  dependencies: new DependencyInvocation(
                    $Example.unnamedConstructor,
                    const [],
                  ),
                )
              ],
              include: [
                new ModuleElement(
                  provide: [
                    new UseClassProviderElement(
                      new TypeTokenElement(urlOf($Dependency)),
                      urlOf($Dependency),
                      dependencies: new DependencyInvocation(
                        $Dependency.unnamedConstructor,
                        const [],
                      ),
                    )
                  ],
                  include: [],
                )
              ],
            ),
          );
        });
      });

      test('should deduplicate Providers with matching tokens', () {
        final module = reader.parseModule($newModuleC);
        final providers = module.flatten();

        expect(providers, hasLength(3));
        expect(reader.deduplicateProviders(providers), hasLength(2));
      });
    });
  });
}
