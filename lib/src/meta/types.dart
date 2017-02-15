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
    final srcMetadata = new AssetId('angular2', 'lib/src/core/metadata.dart');
    final srcDecorators = new AssetId(
      'angular2',
      'lib/src/core/di/decorators.dart',
    );
    final libMetadata = resolver.getLibrary(srcMetadata);
    if (libMetadata == null) {
      throw new ArgumentError(
        'Could not resolve metadata types. Dependencies may be missing.',
      );
    }
    final libDecorators = resolver.getLibrary(srcDecorators);
    if (libDecorators == null) {
      throw new ArgumentError(
        'Could not resolve DI metadata types. Dependencies may be missing.',
      );
    }
    return new _LibraryStaticTypes([libMetadata, libDecorators]);
  }

  const StaticTypes._();

  bool _isA(DartType staticType, Type runtimeType);

  bool _isExactly(DartType staticType, Type runtimeType);

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
      return _isExactly(staticType, runtimeType);
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
      return _isExactly(staticType, runtimeType);
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
}
