import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:angular_compiler/angular_compiler.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

void main() {
  const angular = 'package:angular/angular.dart';

  Future<ClassElement> resolveAndGet(String source, [String name]) async {
    final resolved = await resolveSource('''
      library _test;
      import '$angular';\n\n$source''');
    final library = resolved.getLibraryByName('_test');
    return name != null
        ? library.getType(name)
        : library.definingCompilationUnit.types.first;
  }

  // These tests analyze whether our $Meta types are pointing to the right URLs.
  group('should analyze ', () {
    test('@Directive', () async {
      final aDirective = await resolveAndGet(r'''
      @Directive()
      class ADirective {}
    ''');
      expect($Directive.firstAnnotationOfExact(aDirective), isNotNull);
    });

    test('@Component', () async {
      final aComponent = await resolveAndGet(r'''
      @Component()
      class AComponent {}
    ''');
      expect($Component.firstAnnotationOfExact(aComponent), isNotNull);
    });
  });

  test('@Pipe', () async {
    final aPipe = await resolveAndGet(r'''
      @Pipe('aPipe')
      class APipe {}
    ''');
    expect($Pipe.firstAnnotationOfExact(aPipe), isNotNull);
  });

  test('@Injectable', () async {
    final anInjectable = await resolveAndGet(r'''
      @Injectable()
      class AnInjectable {}
    ''');
    expect($Injectable.firstAnnotationOfExact(anInjectable), isNotNull);
  });

  test('@Attribute', () async {
    final aComponent = await resolveAndGet(r'''
      class AComponent {
        AComponent(@Attribute('name') String name);
      }
    ''');
    final depParam = aComponent.constructors.first.parameters.first;
    expect($Attribute.firstAnnotationOfExact(depParam), isNotNull);
  });

  test('@Inject', () async {
    final aComponent = await resolveAndGet(r'''
      class AComponent {
        AComponent(@Inject(#dep) List dep);
      }
    ''');
    final depParam = aComponent.constructors.first.parameters.first;
    expect($Inject.firstAnnotationOfExact(depParam), isNotNull);
  });

  test('@Optional', () async {
    final aComponent = await resolveAndGet(r'''
      class AComponent {
        AComponent(@Optional() List dep);
      }
    ''');
    final depParam = aComponent.constructors.first.parameters.first;
    expect($Optional.firstAnnotationOfExact(depParam), isNotNull);
  });

  test('@Self', () async {
    final aComponent = await resolveAndGet(r'''
      class AComponent {
        AComponent(@Self() List dep);
      }
    ''');
    final depParam = aComponent.constructors.first.parameters.first;
    expect($Self.firstAnnotationOfExact(depParam), isNotNull);
  });

  test('@SkipSelf', () async {
    final aComponent = await resolveAndGet(r'''
      class AComponent {
        AComponent(@SkipSelf() List dep);
      }
    ''');
    final depParam = aComponent.constructors.first.parameters.first;
    expect($SkipSelf.firstAnnotationOfExact(depParam), isNotNull);
  });

  test('@Host', () async {
    final aComponent = await resolveAndGet(r'''
      class AComponent {
        AComponent(@Host() List dep);
      }
    ''');
    final depParam = aComponent.constructors.first.parameters.first;
    expect($Host.firstAnnotationOfExact(depParam), isNotNull);
  });

  test('@ContentChildren', () async {
    final aComponent = await resolveAndGet(r'''
      class AComponent {
        @ContentChildren()
        List<AChild> children;
      }
      
      class AChild {}
    ''');
    final queryField = aComponent.fields.first;
    expect($ContentChildren.firstAnnotationOfExact(queryField), isNotNull);
  });

  test('@ContentChild', () async {
    final aComponent = await resolveAndGet(r'''
      class AComponent {
        @ContentChild()
        AChild child;
      }
      
      class AChild {}
    ''');
    final queryField = aComponent.fields.first;
    expect($ContentChild.firstAnnotationOfExact(queryField), isNotNull);
  });

  test('@ViewChildren', () async {
    final aComponent = await resolveAndGet(r'''
      class AComponent {
        @ViewChildren()
        List<AChild> children;
      }
      
      class AChild {}
    ''');
    final queryField = aComponent.fields.first;
    expect($ViewChildren.firstAnnotationOfExact(queryField), isNotNull);
  });

  test('@ViewChild', () async {
    final aComponent = await resolveAndGet(r'''
      class AComponent {
        @ViewChild()
        AChild children;
      }
      
      class AChild {}
    ''');
    final queryField = aComponent.fields.first;
    expect($ViewChild.firstAnnotationOfExact(queryField), isNotNull);
  });

  test('@Input', () async {
    final aComponent = await resolveAndGet(r'''
      class AComponent {
        @Input()
        String name;
      }
    ''');
    final inputField = aComponent.fields.first;
    expect($Input.firstAnnotationOfExact(inputField), isNotNull);
  });

  test('@Output', () async {
    final aComponent = await resolveAndGet(r'''
      class AComponent {
        @Output()
        Stream get event => null;
      }
    ''');
    final outputGetter = aComponent.accessors.first;
    expect($Output.firstAnnotationOfExact(outputGetter), isNotNull);
  });

  test('@HostBinding', () async {
    final aComponent = await resolveAndGet(r'''
      class AComponent {
        @HostBinding()
        String get name => 'name';
      }
    ''');
    final hostGetter = aComponent.accessors.first;
    expect($HostBinding.firstAnnotationOfExact(hostGetter), isNotNull);
  });

  test('@HostListener', () async {
    final aComponent = await resolveAndGet(r'''
      class AComponent {
        @HostListener('event')
        void onEvent() {}
      }
    ''');
    final hostMethod = aComponent.methods.first;
    expect($HostListener.firstAnnotationOfExact(hostMethod), isNotNull);
  });
}
