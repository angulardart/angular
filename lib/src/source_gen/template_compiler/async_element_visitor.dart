import 'dart:async';

import 'package:analyzer/dart/element/element.dart';

class AsyncElementVisitor<R> implements ElementVisitor<Object> {
  R _value;
  final ElementVisitor<Future<R>> _asyncDelegate;
  final List<Future> _futures;

  AsyncElementVisitor(this._asyncDelegate) : _futures = [];

  Future<R> get value async {
    await Future.wait(_futures);
    return _value;
  }

  Object visitClassElement(ClassElement element) {
    _futures.add(_asyncDelegate.visitClassElement(element).then((value) {
      this._value ??= value;
    }));
    return null;
  }

  Object visitCompilationUnitElement(CompilationUnitElement element) {
    _futures
        .add(_asyncDelegate.visitCompilationUnitElement(element).then((value) {
      this._value ??= value;
    }));
    return null;
  }

  Object visitConstructorElement(ConstructorElement element) {
    _futures.add(_asyncDelegate.visitConstructorElement(element).then((value) {
      this._value ??= value;
    }));
    return null;
  }

  Object visitExportElement(ExportElement element) {
    _futures.add(_asyncDelegate.visitExportElement(element).then((value) {
      this._value ??= value;
    }));
    return null;
  }

  Object visitFieldElement(FieldElement element) {
    _futures.add(_asyncDelegate.visitFieldElement(element).then((value) {
      this._value ??= value;
    }));
    return null;
  }

  Object visitFieldFormalParameterElement(FieldFormalParameterElement element) {
    _futures.add(
        _asyncDelegate.visitFieldFormalParameterElement(element).then((value) {
      this._value ??= value;
    }));
    return null;
  }

  Object visitFunctionElement(FunctionElement element) {
    _futures.add(_asyncDelegate.visitFunctionElement(element).then((value) {
      this._value ??= value;
    }));
    return null;
  }

  Object visitFunctionTypeAliasElement(FunctionTypeAliasElement element) {
    _futures.add(
        _asyncDelegate.visitFunctionTypeAliasElement(element).then((value) {
      this._value ??= value;
    }));
    return null;
  }

  Object visitImportElement(ImportElement element) {
    _futures.add(_asyncDelegate.visitImportElement(element).then((value) {
      this._value ??= value;
    }));
    return null;
  }

  Object visitLabelElement(LabelElement element) {
    _futures.add(_asyncDelegate.visitLabelElement(element).then((value) {
      this._value ??= value;
    }));
    return null;
  }

  Object visitLibraryElement(LibraryElement element) {
    _futures.add(_asyncDelegate.visitLibraryElement(element).then((value) {
      this._value ??= value;
    }));
    return null;
  }

  Object visitLocalVariableElement(LocalVariableElement element) {
    _futures
        .add(_asyncDelegate.visitLocalVariableElement(element).then((value) {
      this._value ??= value;
    }));
    return null;
  }

  Object visitMethodElement(MethodElement element) {
    _futures.add(_asyncDelegate.visitMethodElement(element).then((value) {
      this._value ??= value;
    }));
    return null;
  }

  Object visitMultiplyDefinedElement(MultiplyDefinedElement element) {
    _futures
        .add(_asyncDelegate.visitMultiplyDefinedElement(element).then((value) {
      this._value ??= value;
    }));
    return null;
  }

  Object visitParameterElement(ParameterElement element) {
    _futures.add(_asyncDelegate.visitParameterElement(element).then((value) {
      this._value ??= value;
    }));
    return null;
  }

  Object visitPrefixElement(PrefixElement element) {
    _futures.add(_asyncDelegate.visitPrefixElement(element).then((value) {
      this._value ??= value;
    }));
    return null;
  }

  Object visitPropertyAccessorElement(PropertyAccessorElement element) {
    _futures
        .add(_asyncDelegate.visitPropertyAccessorElement(element).then((value) {
      this._value ??= value;
    }));
    return null;
  }

  Object visitTopLevelVariableElement(TopLevelVariableElement element) {
    _futures
        .add(_asyncDelegate.visitTopLevelVariableElement(element).then((value) {
      this._value ??= value;
    }));
    return null;
  }

  Object visitTypeParameterElement(TypeParameterElement element) {
    _futures
        .add(_asyncDelegate.visitTypeParameterElement(element).then((value) {
      this._value ??= value;
    }));
    return null;
  }
}

class AsyncRecursiveElementVisitor<R> implements ElementVisitor<Future<R>> {
  Future<R> visitClassElement(ClassElement element) async {
    await element.visitChildren(this);
    return null;
  }

  Future<R> visitCompilationUnitElement(CompilationUnitElement element) async {
    await element.visitChildren(this);
    return null;
  }

  Future<R> visitConstructorElement(ConstructorElement element) async {
    await element.visitChildren(this);
    return null;
  }

  Future<R> visitExportElement(ExportElement element) async {
    await element.visitChildren(this);
    return null;
  }

  Future<R> visitFieldElement(FieldElement element) async {
    await element.visitChildren(this);
    return null;
  }

  Future<R> visitFieldFormalParameterElement(
      FieldFormalParameterElement element) async {
    await element.visitChildren(this);
    return null;
  }

  Future<R> visitFunctionElement(FunctionElement element) async {
    await element.visitChildren(this);
    return null;
  }

  Future<R> visitFunctionTypeAliasElement(
      FunctionTypeAliasElement element) async {
    await element.visitChildren(this);
    return null;
  }

  Future<R> visitImportElement(ImportElement element) async {
    await element.visitChildren(this);
    return null;
  }

  Future<R> visitLabelElement(LabelElement element) async {
    await element.visitChildren(this);
    return null;
  }

  Future<R> visitLibraryElement(LibraryElement element) async {
    await element.visitChildren(this);
    return null;
  }

  Future<R> visitLocalVariableElement(LocalVariableElement element) async {
    await element.visitChildren(this);
    return null;
  }

  Future<R> visitMethodElement(MethodElement element) async {
    await element.visitChildren(this);
    return null;
  }

  Future<R> visitMultiplyDefinedElement(MultiplyDefinedElement element) async {
    await element.visitChildren(this);
    return null;
  }

  Future<R> visitParameterElement(ParameterElement element) async {
    await element.visitChildren(this);
    return null;
  }

  Future<R> visitPrefixElement(PrefixElement element) async {
    await element.visitChildren(this);
    return null;
  }

  Future<R> visitPropertyAccessorElement(
      PropertyAccessorElement element) async {
    await element.visitChildren(this);
    return null;
  }

  Future<R> visitTopLevelVariableElement(
      TopLevelVariableElement element) async {
    await element.visitChildren(this);
    return null;
  }

  Future<R> visitTypeParameterElement(TypeParameterElement element) async {
    await element.visitChildren(this);
    return null;
  }
}
