import 'package:analyzer/analyzer.dart';

/// Serializes the provided [AstNode] to Dart source, replacing `new` in
/// [InstanceCreationExpression]s and the `@` in [Annotation]s with `const`.
String constify(AstNode node) {
  var writer = new StringBuffer();
  node.accept(new _ConstifyingVisitor(writer));
  return '$writer';
}

class _ConstifyingVisitor extends ToSourceVisitor {
  final StringBuffer writer;

  _ConstifyingVisitor(StringBuffer writer)
      : this.writer = writer,
        super(writer);

  @override
  Object visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (node.keyword.lexeme == 'const') {
      return super.visitInstanceCreationExpression(node);
    } else if (node.keyword.lexeme == 'new') {
      writer.write('const ');
      if (node.constructorName != null) {
        node.constructorName.accept(this);
      }
      if (node.argumentList != null) {
        node.argumentList.accept(this);
      }
    }
    return null;
  }

  @override
  Object visitAnnotation(Annotation node) {
    var hasArguments =
        node.arguments != null && node.arguments.arguments != null;
    if (hasArguments) {
      writer.write('const ');
    }
    if (node.name != null) {
      node.name.accept(this);
    }
    if (node.constructorName != null) {
      writer.write('.');
      node.constructorName.accept(this);
    }
    if (hasArguments) {
      var args = node.arguments.arguments;
      writer.write('(');
      for (var i = 0, iLen = args.length; i < iLen; ++i) {
        if (i != 0) {
          writer.write(', ');
        }
        args[i].accept(this);
      }
      writer.write(')');
    }
    return null;
  }
}
