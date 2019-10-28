import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/resolver.dart' show TypeProvider;
import 'package:angular_analyzer_plugin/errors.dart';

/// Resolve the best type of an `@Input()`/`@Output()` for a class context.
///
/// This handles for instance the case of where a component is generic and its
/// inputs must be instantiated to bounds. It also handles the case where a
/// input is inherited and there's a generic in the inheritance chain that
/// affects the end type.
class BindingTypeResolver {
  final InterfaceType _instantiatedClassType;
  final TypeProvider _typeProvider;
  final AnalysisContext _context;
  final ErrorReporter _errorReporter;

  BindingTypeResolver(ClassElement classElem, TypeProvider typeProvider,
      this._context, this._errorReporter)
      : _instantiatedClassType = _instantiateClass(classElem, typeProvider),
        _typeProvider = typeProvider;

  /// For an `@Output()` on some [getter] of type `Stream<T>`, get the type `T`.
  DartType getEventType(PropertyAccessorElement getter, String name) {
    if (getter != null) {
      // ignore: parameter_assignments
      getter = _instantiatedClassType.lookUpInheritedGetter(getter.name,
          thisType: true);
    }

    if (getter != null && getter.type != null) {
      final returnType = getter.type.returnType;
      if (returnType != null && returnType is InterfaceType) {
        final streamType = _typeProvider.streamType2(_typeProvider.dynamicType);
        final streamedType = _context.typeSystem
            .mostSpecificTypeArgument(returnType, streamType);
        if (streamedType != null) {
          return streamedType;
        } else {
          _errorReporter.reportErrorForOffset(
              AngularWarningCode.OUTPUT_MUST_BE_STREAM,
              getter.nameOffset,
              getter.name.length,
              [name]);
        }
      } else {
        _errorReporter.reportErrorForOffset(
            AngularWarningCode.OUTPUT_MUST_BE_STREAM,
            getter.nameOffset,
            getter.name.length,
            [name]);
      }
    }

    return _typeProvider.dynamicType;
  }

  /// On some `@Input()` [setter] of type `void Function(T)`, get the type `T`.
  DartType getSetterType(PropertyAccessorElement setter) {
    if (setter != null) {
      // ignore: parameter_assignments
      setter = _instantiatedClassType.lookUpInheritedSetter(setter.name,
          thisType: true);
    }

    if (setter != null && setter.type.parameters.length == 1) {
      return setter.type.parameters[0].type;
    }

    return null;
  }

  static InterfaceType _instantiateClass(
      ClassElement classElement, TypeProvider typeProvider) {
    // TODO use `insantiateToBounds` for better all around support
    // See #91 for discussion about bugs related to bounds
    DartType getBound(TypeParameterElement p) => p.bound == null
        ? typeProvider.dynamicType
        : p.bound.resolveToBound(typeProvider.dynamicType);

    final bounds = classElement.typeParameters.map(getBound).toList();
    return classElement.instantiate(
      typeArguments: bounds,
      nullabilitySuffix: NullabilitySuffix.star,
    );
  }
}
