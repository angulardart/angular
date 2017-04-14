@TestOn('vm')
import 'dart:async';
import 'dart:io';

import 'package:analyzer/dart/element/element.dart';
import 'package:angular2/src/meta.dart';
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:func/func.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart' hide Func0, Func1;

void main() {
  // We need to execute within Bazel right now to work.
  //
  // It's possible we could accept other environment variables to work within
  // pub/pub serve, but not a priority right now.
  //
  // See: https://github.com/dart-lang/build/issues/168.
  final runFiles = Platform.environment['RUNFILES'];
  const dirPackages = const String.fromEnvironment('packages-dir');
  const metaFiles = const [
    'angular2|lib/src/core/metadata.dart',
    'angular2|lib/src/core/di/decorators.dart',
    'angular2|lib/src/core/metadata/lifecycle_hooks.dart',
  ];

  if (runFiles == null || dirPackages == null) {
    return;
  }

  Completer<Null> tearDownResolver;
  Completer<Resolver> waitForResolver;

  // We need to run our fake builder in order to resolve part of AngularDart.
  setUpAll(() async {
    tearDownResolver = new Completer<Null>();

    // Read the real `metadata.dart` file(s) to use as a fake source.
    final loadedMetaFiles = new Map<String, String>.fromIterable(
      metaFiles,
      value: (String assetPath) {
        assetPath = assetPath.replaceFirst('|', '/');
        assetPath = p.join(runFiles, dirPackages, assetPath);
        return new File(assetPath).readAsStringSync();
      },
    );

    // Run our builder: we'll use it just to extract the Resolver for tests.
    //
    // The builder will end/release the resolver in tearDownAll.
    waitForResolver = new Completer<Resolver>();
    testBuilder(
      new _GetResolver(expectAsync1((resolver) {
        waitForResolver.complete(resolver);
        return tearDownResolver.future;
      })),
      loadedMetaFiles
        ..addAll({
          'angular2|lib/angular2.dart': r'''
          // Not really angular2.dart, but close as far as metadata goes.
          export 'package:angular2/src/core/di/decorators.dart';
          export 'package:angular2/src/core/metadata.dart';
        ''',
          'stub|lib/stub.dart': r'''
          import 'dart:async';

          import 'package:angular2/angular2.dart';

          // Examples of @Directive and @Component usage.
          // -------------------------------------------------------------------

          @Directive()
          class StubDirective {}

          const someToken = const OpaqueToken('someToken');

          @Component()
          class StubComponent {
            StubComponent(@Inject(someToken) String string) {}

            @Input()
            set stubInput(stubInput) {}

            @Output()
            Stream get stubOutput => new Stream.fromIterable([]);

            @HostBinding()
            String get stubHostBinding;

            @HostListener()
            void stubHostListener() {}

            @Query()
            set stubQuery(stubQuery) {}

            @ViewQuery()
            set stubViewQuery(stubViewQuery) {}

            @ContentChildren()
            set stubContentChildren(stubContentChildren) {}

            @ContentChild()
            set stubContentChild(stubContentChild) {}

            @ViewChildren()
            set stubViewChildren(stubViewChildren) {}

            @ViewChild()
            set stubViewChild(stubViewChild) {}
          }

          @Component()
          class StubOnInit implements OnInit {}

          @Component()
          class StubOnDestroy implements OnDestroy {}

          @Component()
          class StubDoCheck implements DoCheck {}

          @Component()
          class StubOnChanges implements OnChanges {}

          @Component()
          class StubAfterContentInit implements AfterContentInit {}

          @Component()
          class StubAfterContentChecked implements AfterContentChecked {}

          @Component()
          class StubAfterViewInit implements AfterViewInit {}

          @Component()
          class StubAfterViewChecked implements AfterViewChecked {}

          @Injectable()
          class StubInjectable {}

          @Pipe()
          class StubPipe {}

          // Examples of trying to trick our type system. Not supported.
          // -------------------------------------------------------------------

          class CustomDirective implements Directive {
            const CustomDirective();
          }
          class CustomComponent implements Component {
            const CustomComponent();
          }

          @CustomDirective()
          class StubCustomDirective {}

          @CustomComponent()
          class StubCustomComponent {}
        '''
        }),
      isInput: (p) => p.startsWith('stub'),
    );
  });

  tearDownAll(() {
    tearDownResolver.complete();
  });

  group('$AngularMetadataTypes', () {
    Resolver resolver;
    LibraryElement stubLibrary;

    ClassElement stubDirectiveClass;
    ClassElement stubComponentClass;
    ClassElement stubPipeClass;

    ClassElement stubCustomDirectiveClass;
    ClassElement stubCustomComponentClass;

    setUpAll(() async {
      resolver = await waitForResolver.future;
      stubLibrary = resolver.getLibrary(new AssetId('stub', 'lib/stub.dart'));

      stubDirectiveClass = stubLibrary.getType('StubDirective');
      stubComponentClass = stubLibrary.getType('StubComponent');
      stubPipeClass = stubLibrary.getType('StubPipe');

      stubCustomDirectiveClass = stubLibrary.getType('StubCustomDirective');
      stubCustomComponentClass = stubLibrary.getType('StubCustomComponent');
    });

    test('should be able to run test cases', () {
      expect(stubLibrary, isNotNull);
    });

    // Run the same test cases with different implementations.
    <String, Func0<StaticTypes>>{
      'StaticTypes.withMirrors': () => const StaticTypes.withMirrors(),
      'StaticTypes.fromResolver': () => new StaticTypes.fromResolver(resolver),
    }.forEach((name, createStaticTypeResolver) {
      group('$name', () {
        AngularMetadataTypes types;

        setUp(() {
          types = new AngularMetadataTypes(createStaticTypeResolver());
        });

        group('detects StubComponent as', () {
          test('a @Directive', () {
            expect(types.isDirectiveClass(stubComponentClass), isTrue);
          });

          test('a @Component', () {
            expect(types.isComponentClass(stubComponentClass), isTrue);
          });

          test('a @Injectable', () {
            expect(types.isInjectableClass(stubComponentClass), isTrue);
          });
        });

        test('detects @Inject() annotated parameter', () {
          final constructor = stubComponentClass.constructors.first;
          final parameter = constructor.parameters.first;
          expect(types.isInjectParameter(parameter), isTrue);
        });

        test('detects @Input() annotated setters', () {
          final stubInput = stubComponentClass.getSetter('stubInput');
          expect(types.isInputSetter(stubInput), isTrue);
        });

        test('detects @Output() annotated getters', () {
          final stubOutput = stubComponentClass.getGetter('stubOutput');
          expect(types.isOutputGetter(stubOutput), isTrue);
        });

        test('detects @HostBinding() annotated getters', () {
          final stubHostBinding = stubComponentClass.getGetter(
            'stubHostBinding',
          );
          expect(types.isHostBinding(stubHostBinding), isTrue);
        });

        test('detects @HostListener() annotated methods', () {
          final stubHostListener = stubComponentClass.getMethod(
            'stubHostListener',
          );
          expect(types.isHostListener(stubHostListener), isTrue);
        });

        test('detects @Query() annotated setters', () {
          final stubQuery = stubComponentClass.getSetter('stubQuery');
          expect(types.isQuery(stubQuery), isTrue);
        });

        test('detects @ViewQuery() annotated setters', () {
          final stubViewQuery = stubComponentClass.getSetter('stubViewQuery');
          expect(types.isViewQuery(stubViewQuery), isTrue);
        });

        test('detects @ContentChildren() annotated setters', () {
          final stubContentChildren = stubComponentClass.getSetter(
            'stubContentChildren',
          );
          expect(types.isContentChildren(stubContentChildren), isTrue);
        });

        test('detects @ContentChild() annotated setters', () {
          final stubContentChild = stubComponentClass.getSetter(
            'stubContentChild',
          );
          expect(types.isContentChild(stubContentChild), isTrue);
        });

        test('detects @ViewChildren() annotated setters', () {
          final stubViewChildren = stubComponentClass.getSetter(
            'stubViewChildren',
          );
          expect(types.isViewChildren(stubViewChildren), isTrue);
        });

        test('detects @ViewChild() annotated setters', () {
          final stubViewChild = stubComponentClass.getSetter('stubViewChild');
          expect(types.isViewChild(stubViewChild), isTrue);
        });

        <String, Func0<Func1<ClassElement, bool>>>{
          'StubOnInit': () => types.hasOnInit,
          'StubOnDestroy': () => types.hasOnDestroy,
          'StubDoCheck': () => types.hasDoCheck,
          'StubOnChanges': () => types.hasOnChanges,
          'StubAfterContentInit': () => types.hasAfterContentInit,
          'StubAfterContentChecked': () => types.hasAfterContentChecked,
          'StubAfterViewInit': () => types.hasAfterViewInit,
          'StubAfterViewChecked': () => types.hasAfterViewChecked,
        }.forEach((className, getMatcher) {
          test('detects a lifecycle event on $className', () {
            final stubClass = stubLibrary.getType(className);
            expect(getMatcher()(stubClass), isTrue);
          });
        });

        group('detects StubDirective as', () {
          test('a @Directive', () {
            expect(types.isDirectiveClass(stubDirectiveClass), isTrue);
          });

          test('not a @Component', () {
            expect(types.isComponentClass(stubDirectiveClass), isFalse);
          });

          test('a @Injectable', () {
            expect(types.isInjectableClass(stubDirectiveClass), isTrue);
          });
        });

        group('detects StubPipe as', () {
          test('a @Pipe', () {
            expect(types.isPipeClass(stubPipeClass), isTrue);
          });

          test('a @Injectable', () {
            expect(types.isInjectableClass(stubPipeClass), isTrue);
          });
        });

        test('should not allow sub-typing @Directive', () {
          expect(types.isDirectiveClass(stubCustomDirectiveClass), isFalse);
        });

        test('should not allow sub-typing @Component', () {
          expect(types.isComponentClass(stubCustomComponentClass), isFalse);
        });
      });
    });
  });
}

class _GetResolver implements Builder {
  final Func1<Resolver, Future> _getResolver;

  const _GetResolver(this._getResolver);

  @override
  Future build(BuildStep buildStep) async {
    return _getResolver(await buildStep.resolver);
  }

  @override
  List<AssetId> declareOutputs(_) => const [];
}
