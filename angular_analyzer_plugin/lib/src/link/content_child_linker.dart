import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_system.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer/src/generated/constant.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart' show SourceRange;
import 'package:meta/meta.dart';
import 'package:angular_analyzer_plugin/errors.dart';
import 'package:angular_analyzer_plugin/src/link/binding_type_resolver.dart';
import 'package:angular_analyzer_plugin/src/link/directive_provider.dart';
import 'package:angular_analyzer_plugin/src/model.dart';
import 'package:angular_analyzer_plugin/src/standard_components.dart';
import 'package:angular_analyzer_plugin/src/summary/idl.dart';

/// Helper class to create resolved [ContentChild]s from syntactic ones.
///
/// Syntactic [ContentChild]s are pretty simple; they are a field name and
/// offset information for the constant value. Here we resolve the field on a
/// [ClassElement] by name, resolve the constant value of the `@ContentChild`
/// annotation, and resolve that value into a [QueriedChildType] so the query
/// can be matched later against elements in the template.
class ContentChildLinker {
  final TypeSystem _typeSystem;
  final DirectiveProvider _directiveProvider;
  final StandardHtml _standardHtml;
  final ErrorReporter _errorReporter;

  final htmlTypes = {'ElementRef', 'Element', 'HtmlElement'};

  ContentChildLinker(this._typeSystem, this._directiveProvider,
      this._standardHtml, this._errorReporter);

  /// Link [contentChildField] against class of [classElement].
  ///
  /// For a `@ContentChild`, pass [isSingular] `= true`. For a
  /// `@ContentChildren`, pass `false`.
  ContentChild link(
      SummarizedContentChildField contentChildField, ClassElement classElement,
      {bool isSingular}) {
    final member = classElement.lookUpSetter(
        contentChildField.fieldName, classElement.library);
    if (member == null) {
      return null;
    }

    final annotationName = isSingular ? 'ContentChild' : 'ContentChildren';
    final annotation = _getAnnotation(member, annotationName);

    if (annotation == null) {
      return null;
    }

    final annotationValue = annotation.computeConstantValue();

    final nameRange =
        SourceRange(contentChildField.nameOffset, contentChildField.nameLength);
    final typeRange =
        SourceRange(contentChildField.typeOffset, contentChildField.typeLength);
    final bindingSynthesizer = BindingTypeResolver(
        classElement,
        classElement.context.typeProvider,
        classElement.context,
        _errorReporter);

    final setterTransform = isSingular
        ? _transformSetterTypeSingular
        : _transformSetterTypeMultiple;

    // `constantValue.getField()` doesn't do inheritance. Do that ourself.
    final value = _getSelectorWithInheritance(annotationValue);
    final read = _getReadWithInheritance(annotationValue);
    final transformedType = setterTransform(
        bindingSynthesizer.getSetterType(member),
        contentChildField,
        annotationName,
        classElement.context);

    if (read != null) {
      _checkQueriedTypeAssignableTo(transformedType, read, contentChildField,
          '$annotationName(read: $read)');
    }

    if (value?.toStringValue() != null) {
      return _buildStringQueriedContentChild(
        contentChildField: contentChildField,
        classElement: classElement,
        annotationName: annotationName,
        read: read,
        transformedType: transformedType,
        value: value.toStringValue(),
        nameRange: nameRange,
        typeRange: typeRange,
      );
    } else if (value?.toTypeValue() != null) {
      return _buildTypeQueriedContentChild(
        contentChildField: contentChildField,
        annotationName: annotationName,
        read: read,
        transformedType: transformedType,
        valueType: value.toTypeValue(),
        nameRange: nameRange,
        typeRange: typeRange,
      );
    } else {
      _errorReporter.reportErrorForOffset(
          AngularWarningCode.UNKNOWN_CHILD_QUERY_TYPE,
          contentChildField.nameOffset,
          contentChildField.nameLength,
          [contentChildField.fieldName, annotationName]);
    }
    return null;
  }

  ContentChild _buildStringQueriedContentChild({
    @required SummarizedContentChildField contentChildField,
    @required ClassElement classElement,
    @required String annotationName,
    @required DartType read,
    @required DartType transformedType,
    @required String value,
    @required SourceRange nameRange,
    @required SourceRange typeRange,
  }) {
    if (transformedType == _standardHtml.elementClass.type ||
        transformedType == _standardHtml.htmlElementClass.type ||
        read == _standardHtml.elementClass.type ||
        read == _standardHtml.htmlElementClass.type) {
      if (read == null) {
        _errorReporter.reportErrorForOffset(
            AngularWarningCode.CHILD_QUERY_TYPE_REQUIRES_READ,
            nameRange.offset,
            nameRange.length, [
          contentChildField.fieldName,
          annotationName,
          transformedType.name
        ]);
      }
      return ContentChild(contentChildField.fieldName,
          query: LetBoundQueriedChildType(value, read),
          read: read,
          typeRange: typeRange,
          nameRange: nameRange);
    }

    // Take the type -- except, we can't validate DI symbols via `read`.
    final setterType = read == null
        ? transformedType
        : classElement.context.typeProvider.dynamicType;

    return ContentChild(contentChildField.fieldName,
        query: LetBoundQueriedChildType(value, setterType),
        typeRange: typeRange,
        nameRange: nameRange,
        read: read);
  }

  ContentChild _buildTypeQueriedContentChild({
    @required SummarizedContentChildField contentChildField,
    @required String annotationName,
    @required DartType read,
    @required DartType transformedType,
    @required DartType valueType,
    @required SourceRange nameRange,
    @required SourceRange typeRange,
  }) {
    final referencedDirective = _directiveProvider
        .getAngularTopLevel(valueType.element as ClassElement) as Directive;

    QueriedChildType query;
    if (referencedDirective != null) {
      query = DirectiveQueriedChildType(referencedDirective);
    } else if (htmlTypes.contains(valueType.element.name)) {
      query = ElementQueriedChildType();
    } else if (valueType.element.name == 'TemplateRef') {
      query = TemplateRefQueriedChildType();
    } else {
      _errorReporter.reportErrorForOffset(
          AngularWarningCode.UNKNOWN_CHILD_QUERY_TYPE,
          contentChildField.nameOffset,
          contentChildField.nameLength,
          [contentChildField.fieldName, annotationName]);
      return null;
    }

    _checkQueriedTypeAssignableTo(
        transformedType, read ?? valueType, contentChildField, annotationName);

    return ContentChild(contentChildField.fieldName,
        query: query, read: read, typeRange: typeRange, nameRange: nameRange);
  }

  void _checkQueriedTypeAssignableTo(
      DartType setterType,
      DartType annotatedType,
      SummarizedContentChildField field,
      String annotationName) {
    if (setterType != null &&
        !_typeSystem.isSubtypeOf(annotatedType, setterType)) {
      _errorReporter.reportErrorForOffset(
          AngularWarningCode.INVALID_TYPE_FOR_CHILD_QUERY,
          field.typeOffset,
          field.typeLength,
          [field.fieldName, annotationName, annotatedType, setterType]);
    }
  }

  ElementAnnotation _getAnnotation(
      PropertyAccessorElement member, String annotationName) {
    final metadata = List<ElementAnnotation>.from(member.metadata)
      ..addAll(member.variable.metadata);
    final annotations = metadata.where((annotation) =>
        annotation.element?.enclosingElement?.name == annotationName);

    // This can happen for invalid dart
    if (annotations.length != 1) {
      return null;
    }

    return annotations.single;
  }

  /// Get a constant [field] value off of an Object, including inheritance.
  ///
  /// ConstantValue.getField() doesn't look up the inheritance tree. Rather than
  /// hardcoding the inheritance tree in our code, look up the inheritance tree
  /// until either it ends, or we find a "selector" field.
  DartObject _getFieldWithInheritance(DartObject value, String field) {
    final selector = value.getField(field);
    if (selector != null) {
      return selector;
    }

    final _super = value.getField('(super)');
    if (_super != null) {
      return _getFieldWithInheritance(_super, field);
    }

    return null;
  }

  /// See [_getFieldWithInheritance].
  DartType _getReadWithInheritance(DartObject value) {
    final constantVal = _getFieldWithInheritance(value, 'read');
    if (constantVal.isNull) {
      return null;
    }

    return constantVal.toTypeValue();
  }

  /// See [_getFieldWithInheritance].
  DartObject _getSelectorWithInheritance(DartObject value) =>
      _getFieldWithInheritance(value, 'selector');

  DartType _transformSetterTypeMultiple(
      DartType setterType,
      SummarizedContentChildField field,
      String annotationName,
      AnalysisContext context) {
    // construct List<Bottom>, which is a subtype of all List<T>
    final typeProvider = context.typeProvider;
    final listBottom = typeProvider.listType2(typeProvider.bottomType);

    if (!_typeSystem.isSubtypeOf(listBottom, setterType)) {
      _errorReporter.reportErrorForOffset(
          AngularWarningCode.CONTENT_OR_VIEW_CHILDREN_REQUIRES_LIST,
          field.typeOffset,
          field.typeLength,
          [field.fieldName, annotationName, setterType]);

      return typeProvider.dynamicType;
    }

    final iterableType = typeProvider.iterableType2(typeProvider.dynamicType);

    // get T for setterTypes that extend Iterable<T>
    return context.typeSystem
            .mostSpecificTypeArgument(setterType, iterableType) ??
        typeProvider.dynamicType;
  }

  DartType _transformSetterTypeSingular(
          DartType setterType,
          SummarizedContentChildField field,
          String annotationName,
          AnalysisContext analysisContext) =>
      setterType;
}
