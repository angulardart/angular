import 'package:analyzer/dart/ast/ast.dart' hide Directive;
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:angular_analyzer_plugin/src/model.dart';
import 'package:angular_analyzer_plugin/src/model/navigable.dart';

/// Records references to Dart [Element]s into the given [template].
class DartReferencesRecorder extends RecursiveAstVisitor {
  final Map<Element, Navigable> dartToAngularMap;
  final Template template;

  DartReferencesRecorder(this.template, this.dartToAngularMap);

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    final dartElement = node.staticElement;
    if (dartElement != null) {
      final angularElement =
          dartToAngularMap[dartElement] ?? DartElement(dartElement);
      final range = SourceRange(node.offset, node.length);
      template.addRange(range, angularElement);
    }
  }
}
