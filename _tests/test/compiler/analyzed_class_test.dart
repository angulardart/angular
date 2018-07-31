@TestOn('vm')
import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:test/test.dart';
import 'package:angular/src/compiler/analyzed_class.dart';
import 'package:angular/src/compiler/expression_parser/ast.dart';

import '../resolve_util.dart';

void main() {
  group('inferExpressionType', () {
    test('should resolve return type of method with implicit receiver',
        () async {
      final analyzedClass = await analyzeClass('''
        class AppComponent {
          final List<String> _names;
          List<String> getNames() => _names;
        }''');
      final expression = MethodCall(ImplicitReceiver(), 'getNames', []);
      final type = getExpressionType(expression, analyzedClass);
      expect(type.toString(), 'List<String>');
    });

    test('should resolve return type of method with explicit receiver',
        () async {
      final analyzedClass = await analyzeClass('''
        class AppComponent {
          final List<String> names;
        }''');
      final namesExpr = PropertyRead(ImplicitReceiver(), 'names');
      final rangeExpr = MethodCall(namesExpr, 'getRange', [
        LiteralPrimitive(1),
        LiteralPrimitive(4),
      ]);
      final type = getExpressionType(rangeExpr, analyzedClass);
      expect(type.toString(), 'Iterable<String>');
    });

    test('should resolve property type with implicit receiver', () async {
      final analyzedClass = await analyzeClass('''
        class AppComponent {
          final List<int> values;
        }''');
      final expression = PropertyRead(ImplicitReceiver(), 'values');
      final type = getExpressionType(expression, analyzedClass);
      expect(type.toString(), 'List<int>');
    });

    test('should resolve property type with explicit receiver', () async {
      final analyzedClass = await analyzeClass('''
        class AppComponent {
          final List<int> values;
        }''');
      final valuesExpr = PropertyRead(ImplicitReceiver(), 'values');
      final lengthExpr = PropertyRead(valuesExpr, 'length');
      final type = getExpressionType(lengthExpr, analyzedClass);
      expect(type.toString(), 'int');
    });
  });
}

Future<AnalyzedClass> analyzeClass(String source) async {
  final library = await resolve(source);
  final visitor = AnalyzedClassVisitor();
  return library.accept(visitor);
}

class AnalyzedClassVisitor extends RecursiveElementVisitor<AnalyzedClass> {
  @override
  AnalyzedClass visitClassElement(ClassElement element) {
    return AnalyzedClass(element);
  }

  @override
  AnalyzedClass visitCompilationUnitElement(CompilationUnitElement element) {
    return _visitAll(element.types);
  }

  @override
  AnalyzedClass visitLibraryElement(LibraryElement element) {
    return _visitAll(element.units);
  }

  AnalyzedClass _visitAll(List<Element> elements) {
    for (var element in elements) {
      final analyzedClass = element.accept(this);
      if (analyzedClass != null) return analyzedClass;
    }
    return null;
  }
}
