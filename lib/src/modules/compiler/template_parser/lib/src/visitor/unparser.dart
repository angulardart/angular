part of angular2_template_parser.src.visitor;

/// this is an example [Visitor] implementation used to
/// produce a basic printout of the original source using an efficient
/// [StringBuffer] and lite formatting.  This does not use the original text,
/// so it can be used to produce new html files from
/// modified trees.
///
/// Currently does not handle desugaring from a banana in a box
/// or structural directives.
class Unparser implements Visitor {
  static bool _onElementBody(NgAstNode node) =>
      node is! NgComment &&
      node is! NgElement &&
      node is! NgText &&
      node is! NgBinding;

  final StringBuffer _buffer = new StringBuffer();
  int _level = 0;

  Unparser();

  void _indent() {
    _level++;
  }

  void _unindent() {
    _level--;
  }

  String get _indentation => '  ' * _level;

  @override
  void visitAttribute(NgAttribute node) {
    _buffer.write(' ${node.name}');
    if (node.value != null) {
      _buffer.write('="${node.value}"');
    }
  }

  @override
  void visitBinding(NgBinding node) {
    _buffer.write(' #${node.name}');
  }

  @override
  void visitComment(NgComment node) {
    _buffer.writeln('$_indentation ${node.source.text}');
  }

  @override
  void visitText(NgText node) {
    _buffer.writeln('$_indentation${node.source.text}');
  }

  @override
  void visitElement(NgElement node) {
    _buffer.write('$_indentation<${node.name}');

    for (final node in node.childNodes.takeWhile(_onElementBody)) {
      node.visit(this);
    }
    _buffer.writeln('>');
    _indent();

    for (final node in node.childNodes.skipWhile(_onElementBody)) {
      node.visit(this);
    }
    _unindent();
    _buffer.writeln('$_indentation</${node.name}>');
  }

  @override
  void visitEvent(NgEvent node) {
    _buffer.write(' (${node.name})=${node.value}');
  }

  @override
  void visitInterpolation(NgInterpolation node) {
    _buffer.writeln('$_indentation{{${node.value}}}');
  }

  @override
  void visitProperty(NgProperty node) {
    _buffer.write(' [${node.name}]="${node.value}"');
  }

  @override
  String toString() => _buffer.toString();
}
