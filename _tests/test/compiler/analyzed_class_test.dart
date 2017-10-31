@TestOn('vm')
import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';
import 'package:angular/src/compiler/analyzed_class.dart';
import 'package:angular/src/compiler/expression_parser/ast.dart';

void main() {
  group('inferExpressionType', () {
    test('should infer MethodCall with implicit receiver', () async {
      final analyzedClass = await analyzeClass('''
        class AppComponent {
          final List<String> _names;
          List<String> getNames() => _names;
        }''');
      final expression = new MethodCall(new ImplicitReceiver(), 'getNames', []);
      final type = getExpressionType(expression, analyzedClass);
      expect(type.toString(), 'List<String>');
    });

    test('should infer dynamic for method with explicit receiver', () async {
      final analyzedClass = await analyzeClass('''
        class AppComponent {
          final List<String> names;
        }''');
      final namesExpr = new PropertyRead(new ImplicitReceiver(), 'names');
      final rangeExpr = new MethodCall(namesExpr, 'getRange', [
        new LiteralPrimitive(1),
        new LiteralPrimitive(4),
      ]);
      final type = getExpressionType(rangeExpr, analyzedClass);
      expect(type.toString(), 'dynamic');
    });

    test('should infer PropertyRead with implicit receiver', () async {
      final analyzedClass = await analyzeClass('''
        class AppComponent {
          final List<int> values;
        }''');
      final expression = new PropertyRead(new ImplicitReceiver(), 'values');
      final type = getExpressionType(expression, analyzedClass);
      expect(type.toString(), 'List<int>');
    });

    test('should infer dynamic for property with explicit receiver', () async {
      final analyzedClass = await analyzeClass('''
        class AppComponent {
          final List<int> values;
        }''');
      final valuesExpr = new PropertyRead(new ImplicitReceiver(), 'values');
      final lengthExpr = new PropertyRead(valuesExpr, 'length');
      final type = getExpressionType(lengthExpr, analyzedClass);
      expect(type.toString(), 'dynamic');
    });
  });
}

Future<AnalyzedClass> analyzeClass(String source) async {
  final testAssetId = new AssetId('analyzed_class_test', 'lib/test.dart');
  final library = await resolveSource(
      source, (resolver) => resolver.libraryFor(testAssetId),
      inputId: testAssetId);
  final visitor = new AnalyzedClassVisitor();
  return library.accept(visitor);
}

class AnalyzedClassVisitor extends RecursiveElementVisitor<AnalyzedClass> {
  @override
  AnalyzedClass visitClassElement(ClassElement element) {
    return new AnalyzedClass(element);
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
