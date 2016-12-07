import 'package:analyzer/analyzer.dart';

/// Serializes the provided [AstNode] to Dart source, replacing `new` in
/// [InstanceCreationExpression]s and the `@` in [Annotation]s with `const`.
String constify(AstNode node) {
  var sink = new StringBuffer();
  node.accept(new _ConstifyingVisitor(sink));
  return sink.toString();
}

class _ConstifyingVisitor extends ToSourceVisitor2 {
  _ConstifyingVisitor(StringSink sink) : super(sink);

  @override
  Object visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (node.keyword.lexeme == 'const') {
      return super.visitInstanceCreationExpression(node);
    } else if (node.keyword.lexeme == 'new') {
      sink.write('const ');
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
      sink.write('const ');
    }
    if (node.name != null) {
      node.name.accept(this);
    }
    if (node.constructorName != null) {
      sink.write('.');
      node.constructorName.accept(this);
    }
    if (hasArguments) {
      var args = node.arguments.arguments;
      sink.write('(');
      for (var i = 0, iLen = args.length; i < iLen; ++i) {
        if (i != 0) {
          sink.write(', ');
        }
        args[i].accept(this);
      }
      sink.write(')');
    }
    return null;
  }
}
