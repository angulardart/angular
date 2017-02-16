import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:angular2/src/core/metadata.dart';
import 'package:build/build.dart';
import 'package:source_gen/src/annotation.dart';

/// An abstraction around comparing types statically (at compile-time).
abstract class StaticTypes {
  /// Creates a [MetadataTypes] that uses runtime reflection.
  const factory StaticTypes.withMirrors({
    bool checkSubTypes,
  }) = _MirrorsStaticTypes;

  /// Creates a [MetadataTypes] by retrieving exact types from [resolver].
  ///
  /// With _analysis summaries_ this should be a relatively cheap operation but
  /// the resulting [MetadataTypes] class should still be cached whenever
  /// possible.
  ///
  /// Throws an [ArgumentError] if [resolver] was not able to lookup type
  /// information for Angular's metadata classes - this is usually a sign that
  /// dependencies or imports are missing.
  factory StaticTypes.fromResolver(
    Resolver resolver, {
    bool checkSubTypes,
  }) {
    assert(resolver != null);
    final metaLibs = const [
      'angular2|lib/src/core/metadata.dart',
      'angular2|lib/src/core/di/decorators.dart',
      'angular2|lib/src/core/metadata/lifecycle_hooks.dart',
    ].map((path) => new AssetId.parse(path)).map((asset) {
      final lib = resolver.getLibrary(asset);
      if (lib == null) {
        throw new UnsupportedError('Could not resolve required "$asset".');
      }
      return lib;
    });
    return new _LibraryStaticTypes(metaLibs);
  }

  const StaticTypes._();

  bool _isA(DartType staticType, Type runtimeType);

  bool _isExactly(DartType staticType, Type runtimeType);

  // More precisely matches the behavior of the transformer-based version.
  //
  // _isA without _checkSubTypes returns true iff either the static type is
  // *exactly* the comparison type or if it directly implements the
  // comparison type.
  bool _isExactlyOrImplementsDirectly(DartType staticType, Type runtimeType) {
    if (_isExactly(staticType, runtimeType)) {
      return true;
    }
    final clazz = staticType.element;
    if (clazz is ClassElement) {
      return clazz.interfaces.any((type) => _isExactly(type, runtimeType));
    }
    return false;
  }

  /// Returns whether [type] is exactly Angular's [Attribute] type.
  bool isAttribute(DartType type) => _isExactly(type, Attribute);

  /// Returns whether [type] is exactly Angular's [Component] type.
  bool isComponent(DartType type) => _isExactly(type, Component);

  /// Returns whether [type] is exactly Angular's [Directive] type.
  bool isDirective(DartType type) => _isExactly(type, Directive);

  /// Returns whether [type] is exactly Angular's [Inject] type.
  bool isInject(DartType type) => _isExactly(type, Inject);

  /// Returns whether [type] is exactly Angular's [Optional] type.
  bool isOptional(DartType type) => _isExactly(type, Optional);

  /// Returns whether [type] is exactly Angular's [Self] type.
  bool isSelf(DartType type) => _isExactly(type, Self);

  /// Returns whether [type] is exactly Angular's [SkipSelf] type.
  bool isSkipSelf(DartType type) => _isExactly(type, SkipSelf);

  /// Returns whether [type] is exactly Angular's [Host] type.
  bool isHost(DartType type) => _isExactly(type, Host);

  /// Returns whether [type] is considered to be [Injectable].
  bool isInjectable(DartType type) => _isExactly(type, Injectable);

  /// Returns whether [type] is exactly Angular's [Pipe] type.
  bool isPipe(DartType type) => _isExactly(type, Pipe);

  /// Returns whether [type] is exactly Angular's [Query] type.
  bool isQuery(DartType type) => _isExactly(type, Query);

  /// Returns whether [type] is exactly Angular's [ViewQuery] type.
  bool isViewQuery(DartType type) => _isExactly(type, ViewQuery);

  /// Returns whether [type] is exactly Angular's [ContentChild] type.
  bool isContentChild(DartType type) => _isExactly(type, ContentChild);

  /// Returns whether [type] is exactly Angular's [ContentChildren] type.
  bool isContentChildren(DartType type) => _isExactly(type, ContentChildren);

  /// Returns whether [type] is exactly Angular's [ViewChild] type.
  bool isViewChild(DartType type) => _isExactly(type, ViewChild);

  /// Returns whether [type] is exactly Angular's [ViewChildren] type.
  bool isViewChildren(DartType type) => _isExactly(type, ViewChildren);

  /// Returns whether [type] is exactly Angular's [Input] type.
  bool isInput(DartType type) => _isExactly(type, Input);

  /// Returns whether [type] is exactly Angular's [Output] type.
  bool isOutput(DartType type) => _isExactly(type, Output);

  /// Returns whether [type] is exactly Angular's [Output] type.
  bool isHostBinding(DartType type) => _isExactly(type, HostBinding);

  /// Returns whether [type] is exactly Angular's [Output] type.
  bool isHostListener(DartType type) => _isExactly(type, HostListener);

  /// Returns whether [type] is or inherits from [AfterContentInit].
  bool isAfterContentInit(DartType type) => _isA(type, AfterContentInit);

  /// Returns whether [type] is or inherits from [AfterContentChecked].
  bool isAfterContentChecked(DartType type) => _isA(type, AfterContentChecked);

  /// Returns whether [type] is or inherits from [AfterViewInit].
  bool isAfterViewInit(DartType type) => _isA(type, AfterViewInit);

  /// Returns whether [type] is or inherits from [AfterViewChecked].
  bool isAfterViewChecked(DartType type) => _isA(type, AfterViewChecked);

  /// Returns whether [type] is or inherits from [OnChanges].
  bool isOnChanges(DartType type) => _isA(type, OnChanges);

  /// Returns whether [type] is or inherits from [OnDestroy].
  bool isOnDestroy(DartType type) => _isA(type, OnDestroy);

  /// Returns whether [type] is or inherits from [OnInit].
  bool isOnInit(DartType type) => _isA(type, OnInit);

  /// Returns whether [type] is or inherits from [DoCheck].
  bool isDoCheck(DartType type) => _isA(type, DoCheck);
}

/// Implementation that uses runtime reflection to do type comparisons.
class _MirrorsStaticTypes extends StaticTypes {
  final bool _checkSubTypes;

  const _MirrorsStaticTypes({bool checkSubTypes: false})
      : _checkSubTypes = checkSubTypes,
        super._();

  @override
  bool _isA(DartType staticType, Type runtimeType) {
    if (!_checkSubTypes) {
      return _isExactlyOrImplementsDirectly(staticType, runtimeType);
    }
    final element = staticType.element;
    if (element is ClassElement) {
      return element.allSupertypes.any((t) => matchTypes(runtimeType, t));
    }
    return false;
  }

  @override
  bool _isExactly(DartType staticType, Type runtimeType) {
    return matchTypes(runtimeType, staticType);
  }
}

/// Implementation that uses other [DartType]s when doing type comparisons.
class _LibraryStaticTypes extends StaticTypes {
  static final _staticType = new Expando<DartType>();

  final bool _checkSubTypes;
  final Iterable<LibraryElement> _metaLibraries;

  _LibraryStaticTypes(
    this._metaLibraries, {
    bool checkSubTypes: false,
  })
      : _checkSubTypes = checkSubTypes,
        super._();

  DartType _getStaticType(Type runtimeType) {
    var staticType = _staticType[runtimeType];
    if (staticType == null) {
      ClassElement clazz;
      for (final lib in _metaLibraries) {
        clazz = lib.getType('$runtimeType');
        if (clazz != null) break;
      }
      staticType = _staticType[runtimeType] = clazz.type;
    }
    return staticType;
  }

  @override
  bool _isA(DartType staticType, Type runtimeType) {
    if (!_checkSubTypes) {
      return _isExactlyOrImplementsDirectly(staticType, runtimeType);
    }
    final comparisonType = _getStaticType(runtimeType);
    return staticType.isSubtypeOf(comparisonType);
  }

  @override
  bool _isExactly(DartType staticType, Type runtimeType) {
    final comparisonType = _getStaticType(runtimeType);
    return staticType == comparisonType;
  }
}

/// A higher-level class that does metadata analysis and extraction for Angular.
class AngularMetadataTypes {
  static DartType _annotationToType(ElementAnnotation annotation) {
    final constant = annotation.computeConstantValue();
    if (constant == null || constant.type == null) {
      if (annotation is ElementAnnotationImpl) {
        throw new ArgumentError(''
            'Could not resolve ${annotation.annotationAst.toSource()}. '
            'This is a common sign that dependencies might be missing or '
            'there are issues with your build configuration. Please file an '
            'issue with the AngularDart team if the problem persists.');
      }
      throw new ArgumentError();
    }
    return constant.type;
  }

  final StaticTypes _staticTypes;

  const AngularMetadataTypes([
    this._staticTypes = const StaticTypes.withMirrors(),
  ]);

  /// Returns whether [clazz] implements `OnInit`.
  bool hasOnInit(ClassElement clazz) => _staticTypes.isOnInit(clazz.type);

  /// Returns whether [clazz] implements `OnDestroy`.
  bool hasOnDestroy(ClassElement clazz) => _staticTypes.isOnDestroy(clazz.type);

  /// Returns whether [clazz] implements `DoCheck`.
  bool hasDoCheck(ClassElement clazz) => _staticTypes.isDoCheck(clazz.type);

  /// Returns whether [clazz] implements `OnChanges`.
  bool hasOnChanges(ClassElement clazz) => _staticTypes.isOnChanges(clazz.type);

  /// Returns whether [clazz] implements `AfterContentInit`.
  bool hasAfterContentInit(ClassElement clazz) =>
      _staticTypes.isAfterContentInit(clazz.type);

  /// Returns whether [clazz] implements `AfterContentChecked`.
  bool hasAfterContentChecked(ClassElement clazz) =>
      _staticTypes.isAfterContentChecked(clazz.type);

  /// Returns whether [clazz] implements `AfterViewInit`.
  bool hasAfterViewInit(ClassElement clazz) =>
      _staticTypes.isAfterViewInit(clazz.type);

  /// Returns whether [clazz] implements `AfterViewChecked`.
  bool hasAfterViewChecked(ClassElement clazz) =>
      _staticTypes.isAfterViewChecked(clazz.type);

  /// Returns whether [clazz] is annotated specifically as `@Component`.
  bool isComponentClass(ClassElement clazz) =>
      clazz.metadata.map(_annotationToType).any(_staticTypes.isComponent);

  /// Returns whether [clazz] is annotated as a `@Directive`-type annotation.
  bool isDirectiveClass(ClassElement clazz) => clazz.metadata
      // This can be simplified once we turn on `checkSubTypes`.
      .map(_annotationToType)
      .any((a) => _staticTypes.isComponent(a) || _staticTypes.isDirective(a));

  /// Returns whether [clazz] is annotated as a `@Injectable`-type annotation.
  bool isInjectableClass(ClassElement clazz) =>
      // This can be simplified once we turn on `checkSubTypes`.
      clazz.metadata.map(_annotationToType).any((a) =>
          _staticTypes.isInjectable(a) ||
          _staticTypes.isComponent(a) ||
          _staticTypes.isDirective(a) ||
          _staticTypes.isPipe(a));

  /// Returns whether [clazz] is annotated specifically as `@Pipe`.
  bool isPipeClass(ClassElement clazz) =>
      clazz.metadata.map(_annotationToType).any(_staticTypes.isPipe);

  /// Returns whether an [element] is a field or getter with `@HostBinding`.
  bool isHostBinding(Element element) {
    assert(element != null);
    if (element is FieldElement ||
        element is PropertyAccessorElement && element.isGetter) {
      return element.metadata
          .map(_annotationToType)
          .any(_staticTypes.isHostBinding);
    }
    return false;
  }

  /// Returns whether an [element] is a field or getter with `@HostBinding`.
  bool isHostListener(MethodElement element) {
    return element.metadata
        .map(_annotationToType)
        .any(_staticTypes.isHostListener);
  }

  /// Returns whether an [element] is a field or setter with `@Input`.
  bool isInputSetter(Element element) {
    assert(element != null);
    if (element is FieldElement ||
        element is PropertyAccessorElement && element.isSetter) {
      return element.metadata.map(_annotationToType).any(_staticTypes.isInput);
    }
    return false;
  }

  /// Returns whether an [element] is a field or getter with `@Output`.
  bool isOutputGetter(Element element) {
    assert(element != null);
    if (element is FieldElement ||
        element is PropertyAccessorElement && element.isGetter) {
      return element.metadata.map(_annotationToType).any(_staticTypes.isOutput);
    }
    return false;
  }

  /// Returns whether an [element] is a field or setter with `@Query`.
  bool isQuery(Element element) {
    assert(element != null);
    if (element is FieldElement ||
        element is PropertyAccessorElement && element.isSetter) {
      return element.metadata.map(_annotationToType).any(_staticTypes.isQuery);
    }
    return false;
  }

  /// Returns whether an [element] is a field or setter with `@ViewQuery`.
  bool isViewQuery(Element element) {
    assert(element != null);
    if (element is FieldElement ||
        element is PropertyAccessorElement && element.isSetter) {
      return element.metadata
          .map(_annotationToType)
          .any(_staticTypes.isViewQuery);
    }
    return false;
  }

  /// Returns whether an [element] is a field or setter with `@ContentChildren`.
  bool isContentChildren(Element element) {
    assert(element != null);
    if (element is FieldElement ||
        element is PropertyAccessorElement && element.isSetter) {
      return element.metadata
          .map(_annotationToType)
          .any(_staticTypes.isContentChildren);
    }
    return false;
  }

  /// Returns whether an [element] is a field or setter with `@ViewChildren`.
  bool isViewChildren(Element element) {
    assert(element != null);
    if (element is FieldElement ||
        element is PropertyAccessorElement && element.isSetter) {
      return element.metadata
          .map(_annotationToType)
          .any(_staticTypes.isViewChildren);
    }
    return false;
  }

  /// Returns whether an [element] is a field or setter with `@ContentChild`.
  bool isContentChild(Element element) {
    assert(element != null);
    if (element is FieldElement ||
        element is PropertyAccessorElement && element.isSetter) {
      return element.metadata
          .map(_annotationToType)
          .any(_staticTypes.isContentChild);
    }
    return false;
  }

  /// Returns whether an [element] is a field or setter with `@ViewChild`.
  bool isViewChild(Element element) {
    assert(element != null);
    if (element is FieldElement ||
        element is PropertyAccessorElement && element.isSetter) {
      return element.metadata
          .map(_annotationToType)
          .any(_staticTypes.isViewChild);
    }
    return false;
  }

  /// Returns whether a [parameter] is annotated with `@Inject`.
  bool isInjectParameter(ParameterElement parameter) =>
      parameter.metadata.map(_annotationToType).any(_staticTypes.isInject);
}
