import 'package:collection/collection.dart';
import 'package:source_span/source_span.dart';

import '../ast.dart';
import '../hash.dart';
import '../token/tokens.dart';
import '../visitor.dart';

const _listEquals = const ListEquality();

/// Represents an `<ng-container>` element.
///
/// This is a logical container that has no effect on layout in the DOM.
///
/// Clients should not extend, implement, or mix-in this class.
abstract class ContainerAst implements StandaloneTemplateAst {
  factory ContainerAst({
    List<StandaloneTemplateAst> childNodes,
    List<StarAst> stars,
  }) = _SyntheticContainerAst;

  factory ContainerAst.from(
    TemplateAst origin, {
    List<StandaloneTemplateAst> childNodes,
    List<StarAst> stars,
  }) = _SyntheticContainerAst.from;

  factory ContainerAst.parsed(
    SourceFile sourceFile,
    NgToken beginToken,
    NgToken endToken, {
    List<StandaloneTemplateAst> childNodes,
    List<StarAst> stars,
  }) = _ParsedContainerAst;

  /// Star assignments.
  List<StarAst> get stars;

  @override
  R accept<R, C>(TemplateAstVisitor<R, C> visitor, [C context]) {
    return visitor.visitContainer(this, context);
  }

  @override
  bool operator ==(Object o) {
    return o is ContainerAst &&
        _listEquals.equals(childNodes, o.childNodes) &&
        _listEquals.equals(stars, o.stars);
  }

  @override
  int get hashCode {
    return hashObjects([
      _listEquals.hash(childNodes),
      _listEquals.hash(stars),
    ]);
  }

  @override
  String toString() {
    final buffer = new StringBuffer('$ContainerAst { ');
    if (stars.isNotEmpty) {
      buffer
        ..write('stars=')
        ..writeAll(stars, ', ')
        ..write(' ');
    }
    if (childNodes.isNotEmpty) {
      buffer
        ..write('childNodes=')
        ..writeAll(childNodes, ', ')
        ..write(' ');
    }
    buffer.write('}');
    return buffer.toString();
  }
}

class _ParsedContainerAst extends TemplateAst with ContainerAst {
  _ParsedContainerAst(
    SourceFile sourceFile,
    NgToken beginToken,
    NgToken endToken, {
    this.childNodes: const [],
    this.stars: const [],
  }) : super.parsed(beginToken, endToken, sourceFile);

  @override
  final List<StandaloneTemplateAst> childNodes;

  @override
  final List<StarAst> stars;
}

class _SyntheticContainerAst extends SyntheticTemplateAst with ContainerAst {
  _SyntheticContainerAst({
    this.childNodes: const [],
    this.stars: const [],
  });

  _SyntheticContainerAst.from(
    TemplateAst origin, {
    this.childNodes: const [],
    this.stars: const [],
  }) : super.from(origin);

  @override
  final List<StandaloneTemplateAst> childNodes;

  @override
  final List<StarAst> stars;
}
