import 'package:collection/collection.dart';
import 'package:source_span/source_span.dart';

import '../ast.dart';
import '../hash.dart';
import '../token/tokens.dart';
import '../visitor.dart';

const _listEquals = ListEquality();

/// Represents an `<ng-container>` element.
///
/// This is a logical container that has no effect on layout in the DOM.
///
/// Clients should not extend, implement, or mix-in this class.
abstract class ContainerAst implements StandaloneTemplateAst {
  factory ContainerAst({
    List<AnnotationAst> annotations,
    List<StandaloneTemplateAst> childNodes,
    List<StarAst> stars,
  }) = _SyntheticContainerAst;

  factory ContainerAst.from(
    TemplateAst origin, {
    List<AnnotationAst> annotations,
    List<StandaloneTemplateAst> childNodes,
    List<StarAst> stars,
  }) = _SyntheticContainerAst.from;

  factory ContainerAst.parsed(
    SourceFile sourceFile,
    NgToken beginToken,
    NgToken endToken,
    CloseElementAst closeComplement, {
    List<AnnotationAst> annotations,
    List<StandaloneTemplateAst> childNodes,
    List<StarAst> stars,
  }) = _ParsedContainerAst;

  /// CloseElement complement
  CloseElementAst get closeComplement;
  set closeComplement(CloseElementAst closeComplement);

  /// Annotation assignments.
  List<AnnotationAst> get annotations;

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
        _listEquals.equals(stars, o.stars) &&
        o.closeComplement == closeComplement;
  }

  @override
  int get hashCode {
    return hashObjects([
      _listEquals.hash(childNodes),
      _listEquals.hash(stars),
      closeComplement,
    ]);
  }

  @override
  String toString() {
    final buffer = StringBuffer('$ContainerAst { ');
    if (stars.isNotEmpty) {
      buffer
        ..write('stars=')
        ..writeAll(stars, ', ')
        ..write(' ');
    }
    if (annotations.isNotEmpty) {
      buffer
        ..write('annotations=')
        ..writeAll(annotations, ', ')
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
    NgToken endToken,
    this.closeComplement, {
    this.annotations = const [],
    this.childNodes = const [],
    this.stars = const [],
  }) : super.parsed(beginToken, endToken, sourceFile);

  @override
  CloseElementAst closeComplement;

  @override
  final List<AnnotationAst> annotations;

  @override
  final List<StandaloneTemplateAst> childNodes;

  @override
  final List<StarAst> stars;
}

class _SyntheticContainerAst extends SyntheticTemplateAst with ContainerAst {
  _SyntheticContainerAst({
    this.annotations = const [],
    this.childNodes = const [],
    this.stars = const [],
  }) : closeComplement = CloseElementAst('ng-container');

  _SyntheticContainerAst.from(
    TemplateAst origin, {
    this.annotations = const [],
    this.childNodes = const [],
    this.stars = const [],
  })  : closeComplement = CloseElementAst('ng-container'),
        super.from(origin);

  @override
  CloseElementAst closeComplement;

  @override
  final List<AnnotationAst> annotations;

  @override
  final List<StandaloneTemplateAst> childNodes;

  @override
  final List<StarAst> stars;
}
