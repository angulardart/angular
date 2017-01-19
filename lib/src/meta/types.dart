import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:angular2/src/core/metadata.dart';
import 'package:build/build.dart';
import 'package:source_gen/src/annotation.dart';

/// An abstraction around comparing types statically (at compile-time).
abstract class MetadataTypes {
  /// Creates a [MetadataTypes] that uses runtime reflection.
  const factory MetadataTypes.withMirrors({
    bool checkSubTypes,
  }) = _MirrorsMetadataTypes;

  /// Creates a [MetadataTypes] by retrieving exact types from [resolver].
  ///
  /// With _analysis summaries_ this should be a relatively cheap operation but
  /// the resulting [MetadataTypes] class should still be cached whenever
  /// possible.
  factory MetadataTypes.fromResolver(
    Resolver resolver, {
    bool checkSubTypes,
  }) {
    final srcMetadata = new AssetId('angular2', 'src/meta/core/metadata.dart');
    final libMetadata = resolver.getLibrary(srcMetadata);
    return new _LibraryMetadataTypes(libMetadata);
  }

  const MetadataTypes._();

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

  /// Returns whether [type] is exactly Angular's [Injectable] type.
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
class _MirrorsMetadataTypes extends MetadataTypes {
  final bool _checkSubTypes;

  const _MirrorsMetadataTypes({bool checkSubTypes: false})
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
class _LibraryMetadataTypes extends MetadataTypes {
  final bool _checkSubTypes;
  final LibraryElement _metadataLibrary;

  _LibraryMetadataTypes(this._metadataLibrary, {bool checkSubTypes: false})
      : _checkSubTypes = checkSubTypes,
        super._();

  @override
  bool _isA(DartType staticType, Type runtimeType) {
    if (!_checkSubTypes) {
      return _isExactly(staticType, runtimeType);
    }
    final comparisonType = _metadataLibrary.getType('$runtimeType').type;
    return staticType.isSubtypeOf(comparisonType);
  }

  @override
  bool _isExactly(DartType staticType, Type runtimeType) {
    final comparisonType = _metadataLibrary.getType('$runtimeType').type;
    return staticType == comparisonType;
  }
}
