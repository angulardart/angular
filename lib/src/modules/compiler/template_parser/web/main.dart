import 'dart:html';

import 'package:angular2_template_parser/template_parser.dart';
import 'package:codemirror/codemirror.dart';
import 'package:stack_trace/stack_trace.dart';

void main() {
  final text = querySelector('#html');
  final ast = querySelector('#ast');
  final errors = querySelector('#errors');
  final codeMirror = new CodeMirror.fromTextArea(
    text,
    options: {
      'class': 'column',
      'mode': 'htmlembedded',
      'theme': 'material',
    },
  );
  final parser = const NgTemplateParser();
  codeMirror.focus();
  codeMirror.onChange.listen((_) {
    final String html = codeMirror.call('getValue');
    errors.children.clear();
    try {
      var nodes = parser.parse(html);
      ast.children.clear();
      nodes.forEach((n) => writeNode(ast, n));
    } catch (e, s) {
      errors.children.add(new LIElement()..append(new PreElement()..text = e.toString()));
      window.console.error(Trace.format(s, terse: true));
    }
  });
}

void writeNode(Element container, NgAstNode node, {int indent: 0}) {
  if (node is NgAttribute) {
    container.append(new DivElement()..text = '${'-' * indent}NgAttribute ${node.name}${node.value != null ? ' = ${node.value}' : ''}');
  } else if (node is NgComment) {
    container.append(new DivElement()..text = '${'-' * indent}NgComment <!--${node.value}-->');
  } else if (node is NgElement) {
    var div = new DivElement()..text = '${'-' * indent}NgElement <${node.name}>';
    container.append(div);
    node.childNodes.forEach((c) => writeNode(div, c, indent: indent + 2));
  } else if (node is NgText) {
    var escaped = node.value;
    escaped = Uri.encodeQueryComponent(escaped);
    container.append(new DivElement()..text = '${'-' * indent}NgText $escaped');
  }
}